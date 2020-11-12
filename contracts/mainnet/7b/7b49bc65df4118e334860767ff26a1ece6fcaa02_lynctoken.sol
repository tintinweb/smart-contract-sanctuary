// SPDX-License-Identifier: MIT

    /**
     * LYNC Network
     * https://lync.network
     *
     * Additional details for contract and wallet information:
     * https://lync.network/tracking/
     *
     * The cryptocurrency network designed for passive token rewards for its community.
     */

pragma solidity ^0.7.0;

import "./safemath.sol";

contract LYNCToken {

    //Enable SafeMath
    using SafeMath for uint256;

    //Token details
    string constant public name = "LYNC Network";
    string constant public symbol = "LYNC";
    uint8 constant public decimals = 18;

    //Reward pool and owner address
    address public owner;
    address public rewardPoolAddress;

    //Supply and tranasction fee
    uint256 public maxTokenSupply = 1e24;   // 1,000,000 tokens
    uint256 public feePercent = 1;          // initial transaction fee percentage
    uint256 public feePercentMax = 10;      // maximum transaction fee percentage

    //Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner,address indexed _spender, uint256 _tokens);
    event TranserFee(uint256 _tokens);
    event UpdateFee(uint256 _fee);
    event RewardPoolUpdated(address indexed _rewardPoolAddress, address indexed _newRewardPoolAddress);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipRenounced(address indexed _previousOwner, address indexed _newOwner);

    //Mappings
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowances;

    //On deployment
    constructor () {
        owner = msg.sender;
        rewardPoolAddress = address(this);
        balanceOf[msg.sender] = maxTokenSupply;
        emit Transfer(address(0), msg.sender, maxTokenSupply);
    }

    //ERC20 totalSupply
    function totalSupply() public view returns (uint256) {
        return maxTokenSupply;
    }

    //ERC20 transfer
    function transfer(address _to, uint256 _tokens) public returns (bool) {
        transferWithFee(msg.sender, _to, _tokens);
        return true;
    }

    //ERC20 transferFrom
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool) {
        require(_tokens <= balanceOf[_from], "Not enough tokens in the approved address balance");
        require(_tokens <= allowances[_from][msg.sender], "token amount is larger than the current allowance");
        transferWithFee(_from, _to, _tokens);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_tokens);
        return true;
    }

    //ERC20 approve
    function approve(address _spender, uint256 _tokens) public returns (bool) {
        allowances[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    //ERC20 allowance
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    //Transfer with transaction fee applied
    function transferWithFee(address _from, address _to, uint256 _tokens) internal returns (bool) {
        require(balanceOf[_from] >= _tokens, "Not enough tokens in the senders balance");
        uint256 _feeAmount = (_tokens.mul(feePercent)).div(100);
        balanceOf[_from] = balanceOf[_from].sub(_tokens);
        balanceOf[_to] = balanceOf[_to].add(_tokens.sub(_feeAmount));
        balanceOf[rewardPoolAddress] = balanceOf[rewardPoolAddress].add(_feeAmount);
        emit Transfer(_from, _to, _tokens.sub(_feeAmount));
        emit Transfer(_from, rewardPoolAddress, _feeAmount);
        emit TranserFee(_tokens);
        return true;
    }

    //Update transaction fee percentage
    function updateFee(uint256 _updateFee) public onlyOwner {
        require(_updateFee <= feePercentMax, "Transaction fee cannot be greater than 10%");
        feePercent = _updateFee;
        emit UpdateFee(_updateFee);
    }

    //Update the reward pool address
    function updateRewardPool(address _newRewardPoolAddress) public onlyOwner {
        require(_newRewardPoolAddress != address(0), "New reward pool address cannot be a zero address");
        rewardPoolAddress = _newRewardPoolAddress;
        emit RewardPoolUpdated(rewardPoolAddress, _newRewardPoolAddress);
    }

    //Transfer current token balance to the reward pool address
    function rewardPoolBalanceTransfer() public onlyOwner returns (bool) {
        uint256 _currentBalance = balanceOf[address(this)];
        transferWithFee(address(this), rewardPoolAddress, _currentBalance);
        return true;
    }

    //Transfer ownership to new owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //Remove owner from the contract
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner, address(0));
        owner = address(0);
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only current owner can call this function");
        _;
    }
}
