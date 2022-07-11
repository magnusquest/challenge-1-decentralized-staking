pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;

  event Stake(address indexed sender, uint256 amount);
  event Withdraw(address indexed sender, uint256 amount);

  modifier deadlineReached(bool requireReached) {
    uint256 timeRemaining = timeLeft();
    if (requireReached) {
      require(timeRemaining == 0, 'Deadline is not reached');
    }
    _;
  }

  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, 'Staking process already completed');
    _;
  }

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function execute() public stakeNotCompleted deadlineReached(false) {
    uint256 contractBalance = address(this).balance;

    require(contractBalance >= threshold, 'Threshold not reached');

    (bool sent, ) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature('complete()'));
    require(sent, 'exampleExternalContract.complete failed');
  }

  function stake() public payable deadlineReached(false) stakeNotCompleted {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public deadlineReached(true) stakeNotCompleted {
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "You don't have balance to withdraw");
    balances[msg.sender] = 0;
    (bool sent, ) = msg.sender.call{value: userBalance}('');
    require(sent, 'Failed to send user balance back to the user');
  }

  function timeLeft() public view returns (uint256 timeLeft) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}
