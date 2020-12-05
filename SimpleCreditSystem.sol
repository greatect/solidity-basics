// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// 0x4346e6c46c61CAdDF2908458b885E6d4093a5358 on Ropsten testnet
contract SimpleCreditSystem_PracticeOnly{
	struct Credit{
		uint fulfill;
		uint deceive;
	}
	uint constant public creditEditionMax = 1000;
	address public manager;
	address public calculatorReference;
	mapping(address => bool) hasRight;
	mapping(address => Credit) credits;

	event CalculatorChanged(address calculator);
	event NewJudgeJoined(address judge);
	event ScoreReport(address user, uint score);

	constructor(){
		manager = msg.sender;
		calculatorReference = address(this);
	}
	/// The score of a credit will be calculated within contract `calculator`
	function setNewCalculator(address calculator) public{
		require(msg.sender == manager);
		calculatorReference = calculator;
		emit CalculatorChanged(calculator);
	}
	/// Become a judge using credential provided by the manager
	function register(bytes memory credential) payable public{
		uint8 v;
		bytes32 r;
		bytes32 s;
		require(credential.length == 65);
		bytes32 msg_hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, this))));
        assembly {
            r := mload(add(credential, 32))
            s := mload(add(credential, 64))
            v := byte(0, mload(add(credential, 96)))
        }
		require(ecrecover(msg_hash, v, r, s) == manager);
		hasRight[msg.sender] = true;
		emit NewJudgeJoined(msg.sender);
	}
	/// Record to the credit system with `fulfills` fulfills
	function incCredit(address user, uint fulfills) public{
		require(hasRight[msg.sender]);
		require(fulfills <= creditEditionMax);
		credits[user].fulfill += fulfills;
	}
	/// Record to the credit system with `deceives` deceives
	function decCredit(address user, uint deceives) public{
		require(hasRight[msg.sender]);
		require(deceives <= creditEditionMax);
		credits[user].deceive += deceives;
	}
	/// Get credit score of user `user` using the current calculator 
	function getCreditScore(address user) public{
		(bool success, bytes memory score_raw) = calculatorReference.call(abi.encodeWithSignature("calculate(uint256,uint256)", credits[user].fulfill, credits[user].deceive));
		require(success);
		emit ScoreReport(user, abi.decode(score_raw, (uint)));
	}
	/// @dev it is called by getCreditScore() using "call", so it has to be declared as public
	function calculate(uint x, uint y) public pure returns (uint){
		y = y*2;
		if(x <= y) return 0;
		return x-y;
	}
}