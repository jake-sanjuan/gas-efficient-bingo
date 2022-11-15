// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Interface to Bingo contract
 */
interface IBingo {

  /******************
  /  STRUCTS
  /******************/

  /**
   * @notice Player card, tracks board and spots covered
   * @param boardAndAddress First 25 bytes hold board numbers, last 7 hold first 7 bytes of address
   * @param coveredSpots Keeps track of spots that are covered, 01 set at covered indicies
   */
  struct PlayerCard {
    bytes32 boardAndAddress; // Players numbers and first 7 bytes of address stored as bytes32
    bytes32 coveredSpots; // Bools encoded as bytes32 showing which numbers have been drawn
  }

  /**
   * @notice Information needed for joining and turn tracking per game
   * @param gameInitBlock Block that game was initialized
   * @param lastTurnBlock Block that last turn took place at
   */
  struct GameInfo {
    uint128 gameInitBlock;
    uint128 lastTurnBlock;
  }

  /******************
  /  EVENTS
  /******************/

  /**
   * @notice Emitted when game is joined
   * @param player Address of user joining game
   * @param gameIdx Index of game that user has joined
   */
  event GameJoined(
    address indexed player,
    uint256 indexed gameIdx
  );

  /**
   * @notice Emitted when contract owner draws number
   * @param numberDrawn Number that has been drawn
   * @param gameIdx Index of game that number has been drawn for
   */
  event NumberDrawn(
    uint256 indexed numberDrawn,
    uint256 indexed gameIdx
  );

  /**
   * @notice Emitted when user gets bingo
   * @param player Address of user that got bingo
   * @param gameIdx Index of game that user has joined
   */
  event Bingo(
    address indexed player,
    uint256 indexed gameIdx
  );

  /**
   * @notice Emitted when contract owner creates a game
   * @param gameIdx Index of game that owner has created
   */
  event GameCreated(uint256 indexed gameIdx);

  /**
   * @notice Emitted when contract owner changes fee to join game
   * @param newEntryFee New fee set to join game
   */
  event EntryFeeUpdated(uint80 indexed newEntryFee);
  
  /**
   * @notice Emitted when contract owner changes duration to join game
   * @param newJoinDuration New duration set to join game
   */
  event JoinDurationUpdated(uint8 indexed newJoinDuration);
  
  /**
   * @notice Emitted when contract owner changes duration between turns
   * @param newTurnDuration New duration set between turns
   */
  event TurnDurationUpdated(uint8 indexed newTurnDuration);
  
  /**
   * @notice Emitted when contract owner changes token that game fee is to be paid in
   * @param newFeeToken New fee token
   */
  event FeeTokenUpdated(address indexed newFeeToken);

  /******************
  /  ERRORS
  /******************/

  /**
   * @notice Game does not exist (e.g. Owner had not initialized game index)
   */
  error GameDoesNotExist();

  /**
   * @notice Game is not currently joinable (e.g. join duration has passed)
   */
  error GameNotJoinable();

  /**
   * @notice Owner tries to call draw function early
   */
  error EarlyDraw();

  /**
   * @notice Owner tries to create a game with an index that has already been used
   */
  error GameAlreadyCreated();

  /**
   * @notice Sender of tx and owner of game board do not match
   */
  error SenderPlayerMismatch();

  /**
   * @notice User sends in a bingo index > 11
   */
  error BingoIndexOutOfBounds();

  /**
   * @notice Owner attempts to add a fee token that is the zero address
   */
  error FeeTokenCannotBeZeroAddress();

  /**
   * @notice Owner attempts to set a join duration that is zero
   */
  error JoinDurationMustBeGreaterThanZero();

  /**
   * @notice Entry fee must be greater than zero
   */
  error EntryFeeMustBeGreaterThanZero();

  /******************
  /  FUNCTIONS
  /******************/

  /**
   * @notice Allows player to join game
   * @param gameIdx Game index of game that user is attempting to join
   */
  function joinGame(uint256 gameIdx) external;
  
  /**
   * @notice Allows Owner to draw a number
   * @param gameIdx Game index of game that Owner is drawing for
   */
  function draw(uint256 gameIdx) external;

  /**
   * @notice Allows player check for bingo
   * @param gameIdx Game index of game that user is attempting to check bingo for
   * @param bingoIdx Index of {possibleBingoIdxes}.  Tells function which indexes to check for bingo
   * @param playerIdx Index of players {PlayerCard} in state
   */
  function bingo(uint256 gameIdx, uint256 bingoIdx, uint256 playerIdx) external;
  
  /**
   * @notice Allows Owner to create game
   * @param gameIdx Game index for game that Owner is attempting to create
   */
  function createGame(uint256 gameIdx) external;

  /**
   * @notice Allows owner to join game
   * @param entryFee New entry fee for players to join game
   */
  function updateEntryFee(uint80 entryFee) external;

  /**
   * @notice Allows owner to update join duration
   * @param joinDurationBlocks Number of blocks until players can no longer join game
   */
  function updateJoinDuration(uint8 joinDurationBlocks) external;
  
  /**
   * @notice Allows owner to update turn duration
   * @param turnDurationBlocks New min number of blocks to pass between turns
   */
  function updateTurnDuration(uint8 turnDurationBlocks) external;

  /**
   * @notice Allows owner to update token that game fees will be paid in
   * @param feeToken Token address
   */
  function updateFeeToken(address feeToken) external;
}