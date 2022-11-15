// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IBingo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bingo is IBingo, Ownable {
  IERC20 public feeToken;
  uint80 public entryFee;
  uint8 public joinDurationBlocks;
  uint8 public turnDurationBlocks;

  mapping (uint256 => PlayerCard[]) public playersByGameIdx;
  mapping (uint256 => GameInfo) public gameInfo;

  uint256[][] public possiblebingoIdxes = [
    [0, 1, 2, 3, 4],
    [5, 6, 7, 8, 9],
    [10, 11, 12, 13, 14],
    [15, 16, 17, 18, 19],
    [20, 21, 22, 23, 24],
    [0, 5, 10, 15, 20],
    [1, 6, 11, 16, 21],
    [2, 7, 12, 17, 22],
    [3, 8, 13, 18, 23],
    [4, 9, 14, 19, 24],
    [0, 6, 12, 18, 24],
    [4, 8, 12, 16, 20]
  ];

  constructor(
    uint80 _entryFee,
    uint8 _joinDurationBlocks,
    uint8 _turnDurationBlocks,
    address _feeToken
  ) Ownable() {
    updateEntryFee(_entryFee);
    updateJoinDuration(_joinDurationBlocks);
    updateTurnDuration(_turnDurationBlocks);
    updateFeeToken(_feeToken);
  }

  function joinGame(uint256 gameIdx) external {
    if (gameInfo[gameIdx].gameInitBlock + joinDurationBlocks < block.number) revert GameNotJoinable();

    PlayerCard memory _playerCard;
    bytes32 boardAndAddress = _playerCard.boardAndAddress;
    for (uint256 i = 0; i < 25; ++i) {
      // i + 1 resolves case where first number in board is always 0
      boardAndAddress = boardAndAddress | (bytes32(bytes1(uint8(uint256(blockhash(block.number - (i + 1))) % 256))) >> (i * 8));
    }
    // Add first 7 bytes of msg.sender to end of boardAndAddress array, save storage write for address
    for (uint256 i = 0; i < 7; ++i) {
      boardAndAddress = boardAndAddress | (bytes32(bytes20(msg.sender)[i]) >> ((i + 25) * 8));
    }

    _playerCard.boardAndAddress = boardAndAddress;
    playersByGameIdx[gameIdx].push(_playerCard);
    feeToken.transferFrom(msg.sender, address(this), entryFee);

    emit GameJoined(msg.sender, gameIdx);
  }

  function draw(uint256 gameIdx) external onlyOwner {
    PlayerCard[] memory _playerCards = playersByGameIdx[gameIdx];
    GameInfo memory _gameInfo = gameInfo[gameIdx];
    if(_gameInfo.lastTurnBlock + turnDurationBlocks > block.number) revert EarlyDraw();
    if(_playerCards.length == 0) revert GameDoesNotExist();

    // Draw number, remainder of blockhash / 256
    uint8 numberDrawn = uint8(uint256(blockhash(block.number - 1)) % 256);
    for (uint256 j = 0; j < _playerCards.length; ++j) {
      PlayerCard memory _playerCard = _playerCards[j];
      
      bool write;
      for (uint256 i = 0; i < 25; ++i) {
        // If spot on players board is equal to number drawn, 'cover' corresponding index
        if(uint8(_playerCard.boardAndAddress[i]) == numberDrawn) {
          _playerCard.coveredSpots = _playerCard.coveredSpots | bytes32(bytes1(uint8(1))) >> (i * 8);
          write = true;
        }
      }
      // Update storage if change is made in memory, set {write} to false for next iteration
      if (write) {
        playersByGameIdx[gameIdx][j] = _playerCard;
        write = false;
      }
    }
    _gameInfo.lastTurnBlock = uint128(block.number);
    gameInfo[gameIdx] = _gameInfo;

    emit NumberDrawn(numberDrawn, gameIdx);
  }

  function bingo(uint256 gameIdx, uint256 bingoIdx, uint256 playerIdx) external {
    PlayerCard memory _playerCard = playersByGameIdx[gameIdx][playerIdx];
    address sender = msg.sender;

    if (bingoIdx > 11) revert BingoIndexOutOfBounds();
    // Checks that first 7 bytes of sender matches last 7 bytes of {PlayerCard.boardAndAddress}
    for(uint256 i = 0; i < 7; ++i) {
      if (_playerCard.boardAndAddress[i + 25] != bytes20(sender)[i]) {
        revert SenderPlayerMismatch();
      }
    }

    uint256[] memory bingoIdxes = possiblebingoIdxes[bingoIdx];
    for(uint256 i = 0; i < 5; ++i) {
      // Skips free space, will always be idx 12
      if (_playerCard.coveredSpots[bingoIdxes[i]] == 0 && bingoIdxes[i] != 12) {
        return;
      }
    }
    feeToken.transfer(sender, entryFee * playersByGameIdx[gameIdx].length);

    emit Bingo(sender, gameIdx);
  }

  function createGame(uint256 gameIdx) external onlyOwner {
    GameInfo memory _gameInfo = gameInfo[gameIdx];
    if (_gameInfo.gameInitBlock != 0) revert GameAlreadyCreated();

    _gameInfo.gameInitBlock = uint128(block.number);
    _gameInfo.lastTurnBlock = uint128(block.number);
    gameInfo[gameIdx] = _gameInfo;

    emit GameCreated(gameIdx);
  }

  function updateEntryFee(uint80 _entryFee) public onlyOwner {
    if(_entryFee == 0) revert EntryFeeMustBeGreaterThanZero();
    entryFee = _entryFee;

    emit EntryFeeUpdated(_entryFee);
  }

  function updateJoinDuration(uint8 _joinDurationBlocks) public onlyOwner {
    if (_joinDurationBlocks == 0) revert JoinDurationMustBeGreaterThanZero();
    joinDurationBlocks = _joinDurationBlocks;

    emit JoinDurationUpdated(_joinDurationBlocks);
  }

  function updateTurnDuration(uint8 _turnDurationBlocks) public onlyOwner {
    turnDurationBlocks = _turnDurationBlocks;

    emit TurnDurationUpdated(_turnDurationBlocks);
  }

  function updateFeeToken(address _feeToken) public onlyOwner {
    if (_feeToken == address(0)) revert FeeTokenCannotBeZeroAddress();
    feeToken = IERC20(_feeToken);

    emit FeeTokenUpdated(_feeToken);
  }

}
