// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.2;

interface IERC20
{
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PlushFaucet {
    IERC20 token;
    address owner;
    mapping(address=>uint256) nextRequestAt;
    mapping(address=>uint256) generalAmount;
    uint256 faucetDripAmount;
    uint256 faucetTime;
    uint256 threshold;
    bool isActive;

    constructor (address _smtAddress)
    {
        token = IERC20(_smtAddress);
        faucetTime = 24 hours;
        faucetDripAmount = 1 * 10 ** token.decimals();
        threshold = 100 * 10 ** token.decimals();
        owner = msg.sender;
        isActive = true;
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "FaucetError: Caller not owner");
        _;
    }

    function send(address _receiver) external
    {
        require(token.balanceOf(address(this)) >= faucetDripAmount, "FaucetError: Empty");
        require(nextRequestAt[_receiver] < block.timestamp, "FaucetError: Try again later");
        require(generalAmount[_receiver] < threshold, "FaucetError: You have exceeded the maximum number of coins");

        // Next request from the address can be made only after faucetTime
        nextRequestAt[_receiver] = block.timestamp + faucetTime;
        generalAmount[_receiver] += faucetDripAmount;

        token.transfer(_receiver, faucetDripAmount);
    }

    function setTokenAddress(address _tokenAddr) external onlyOwner
    {
        token = IERC20(_tokenAddr);
    }

    function setFaucetDripAmount(uint256 _amount) external onlyOwner
    {
        faucetDripAmount = _amount;
    }

    function setThreshold(uint256 _amount) external onlyOwner
    {
        threshold = _amount;
    }

    function setFaucetTime(uint256 _time) external onlyOwner
    {
        faucetTime = _time;
    }

    function setFaucetActive(bool _isActive) external onlyOwner
    {
        isActive = _isActive;
    }

    function withdrawTokens(address _receiver, uint256 _amount) external onlyOwner
    {
        require(token.balanceOf(address(this)) >= _amount, "FaucetError: Insufficient funds");
        token.transfer(_receiver, _amount);
    }

    function getThreshold() external view returns(uint256)
    {
        return threshold;
    }

    function getFaucetDripAmount() external view returns(uint256)
    {
        return faucetDripAmount;
    }

    function getFaucetBalance() external view returns(uint256)
    {
        return token.balanceOf(address(this));
    }

    function getDistributionTime() external view returns(uint256)
    {
        return faucetTime;
    }

    function getFaucetIsActive() external view returns(bool)
    {
        return isActive;
    }

    function getDistributionOfAddress(address _receiver) external view returns(uint256)
    {
        if(nextRequestAt[_receiver] <= block.timestamp || nextRequestAt[_receiver] == 0){
            return 0;
        }

        return nextRequestAt[_receiver] - block.timestamp;
    }

    function getCanTheAddressReceiveReward(address _receiver) external view returns(bool)
    {
        require(token.balanceOf(address(this)) >= faucetDripAmount, "Faucet is empty");
        require(nextRequestAt[_receiver] < block.timestamp, "You received recently, try again later");
        require(generalAmount[_receiver] < threshold, "You have exceeded the maximum number of coins");

        return true;
    }
}