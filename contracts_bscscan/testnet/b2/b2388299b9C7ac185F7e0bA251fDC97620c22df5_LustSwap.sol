// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}


contract LustSwap{

    address public token;
    uint256 public ratio = 57000;

    address payable public fundsWallet;
    address public adminWallet;

    uint256 public minPerUser;
    uint256 public publicMaxPerUser;

    bool public isPublic = false;


    uint256 public ETH_USD = 400 ether;
    uint256 oracleBlock;

    mapping (address => bool) public whitelist;


    uint256[] public percents;
    uint256[] public prices;

    constructor(
        address _token
    ) public{

        adminWallet = msg.sender;
        token = _token;

    }

    modifier isPoolOpen() {
        StandardToken tokenContract = StandardToken(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > amountOut(msg.value), "!balance");
        _;
    }


    /**
     *  check if the sender is admin
     */
    modifier isAdmin(){
        require(msg.sender == adminWallet, "!admin");
        _;
    }


    /**
     * @dev fallback function
     */
    receive() external payable{
       swap();
    }

    /**
     * @dev swap function
     */
    function swap() isPoolOpen public payable {
        StandardToken tokenContract = StandardToken(token);
        uint256 amount = amountOut(msg.value);
        tokenContract.transfer(msg.sender, amount);
    }


    function amountOut(uint256 _amount) view public returns(uint256){
        uint256 tokenAmount;
        tokenAmount = ratio * _amount;
        return tokenAmount;
    }


    /**
     * @dev Allows admin to withdraw remaining tokens
     */
    function adminWithdraw(address _token, uint256 _amount) isAdmin public{
        StandardToken tokenContract = StandardToken(_token);
        tokenContract.transfer(msg.sender, _amount);
    }

    function adminWithdrawBNB(uint256 _amount) isAdmin public{
        payable(msg.sender).transfer(_amount);
    }


    function adminWhitelistUser(address _user, bool isActive) isAdmin public{
        whitelist[_user] = isActive;
    }

    function setToken(address _token) isAdmin public {
        token = _token;
    }

    function setAdminWallet(address _operatorWallet) isAdmin public {
        adminWallet = _operatorWallet;
    }

    function setRatio(uint256 newRatio) isAdmin public {
        ratio = newRatio;
    }

}