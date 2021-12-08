// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {

    enum State {NOT_STARTED, STARTED, ENDED}

    address payable[] public players;
    address payable public recentWinner;
    address public admin;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;

    uint256 public fee;
    bytes32 public keyhash;

    State public state;

    constructor(
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link,
        uint256 _fee,
        bytes32 _keyhash) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        fee = _fee;
        keyhash = _keyhash;
        state = State.NOT_STARTED;
    }


    function enter() public payable {
        // minimum fee
        require(state == State.STARTED);
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, ,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() onlyOwner public {
        require(state == State.NOT_STARTED, "Can't start a new lottery yet!");
        state = State.STARTED;
    }

    function endLottery() onlyOwner public {
        require(state == State.STARTED);
        state = State.ENDED;
        bytes32 requestId = requestRandomness(keyhash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) 
        internal 
        override 
    {
        require(state == State.ENDED, "Lottery not yet ended!");
        require(_randomness > 0, "Random number not found!");
        uint256 winnerIndex = _randomness % players.length;
        recentWinner = players[winnerIndex];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        state = State.NOT_STARTED;
    }
}