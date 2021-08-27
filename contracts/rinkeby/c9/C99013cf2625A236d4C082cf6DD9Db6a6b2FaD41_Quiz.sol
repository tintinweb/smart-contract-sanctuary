/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Quiz
 * @dev Store & retrieve value for quizes
 */
contract Quiz {
    
    bytes32[] private qustions;
    bytes32[] private answers;
    address[] public participants;
    
    uint public totalParticipants;
    
    mapping(bytes32 => bytes32) private correct_ans;
    mapping(address => mapping(bytes32 => bytes32)) public responses;

    IERC20 public immutable usdao;

    address public immutable admin;
    
    constructor(address _usdao, bytes32[] memory _qs, bytes32[] memory _ans) {

        admin = msg.sender;

        usdao = IERC20(_usdao);

        qustions = _qs;
        answers = _ans;
        
        for(uint8 i; i<(qustions).length; i++) {
            correct_ans[qustions[i]] = answers[i];
        }
    }

    /**
     * @dev Quiz functions should only be called by Admin
     */
    modifier onlyAdmin() {
        require(msg.sender == address(admin), "Can only be called by admin");
        _;
    }

    function registerParticipant(address _p) external onlyAdmin {
        require(!isRegistered(_p), "User already registered");
        participants.push(_p);
        totalParticipants = participants.length;
    }

    function isRegistered(address _user) public view returns (bool isUserRegistered) {
        isUserRegistered = false;
        for (uint256 index = 0; index < totalParticipants; index++) {
            if(participants[index] == _user) isUserRegistered = true;
        }
    }
    
    function displayAns(bytes32 _qs) private view returns(bytes32) {
        return correct_ans[_qs]; 
    }
    
    function isCorrect(bytes32 _qs, bytes32 _userOpt) private view returns(bool) {
        return displayAns(_qs) == _userOpt;
    }

    function userResponse(bytes32 _qs, bytes32 _userOpt, uint amount) external {
        require(isRegistered(msg.sender), "User not registered.");
        require(responses[msg.sender][_qs] == "", "Already answered");
        responses[msg.sender][_qs] = _userOpt;

        if(isCorrect(_qs, _userOpt)) {
            rewardUser(amount);
        }
    }

    function rewardUser(uint amount) private {
        require(usdao.transfer(msg.sender, amount), "Quiz ERR: Reward transfer failed.");
    } 
    
    function usdaoBalance(address user) public view returns(uint){
        return usdao.balanceOf(user);
    }

}