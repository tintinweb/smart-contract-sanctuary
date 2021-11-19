/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity 0.8.9; 


//SPDX-License-Identifier: UNLICENSED



interface ERC20Essential 
{

    function balanceOf(address user) external view returns(uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}




//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;
    mapping(address => bool) public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event SignerUpdated(address indexed signer, bool indexed status);

    constructor() {
        owner = msg.sender;
        signer[msg.sender] = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(signer[msg.sender], 'caller must be signer');
        _;
    }


    function changeSigner(address _signer, bool _status) public onlyOwner {
        signer[_signer] = _status;
        emit SignerUpdated(_signer, _status);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract DthEthBridge is owned {
    
    uint256 public orderID;
    
    

    // This generates a public event of coin received by contract
    event CoinIn(uint256 indexed orderID, address indexed user, uint256 value);
    event CoinOut(uint256 indexed orderID, address indexed user, uint256 value);
    event CoinOutFailed(uint256 indexed orderID, address indexed user, uint256 value);
    event TokenIn(uint256 indexed orderID, address indexed tokenAddress, address indexed user, uint256 value, uint256 chainID);
    event TokenOut(uint256 indexed orderID, address indexed tokenAddress, address indexed user, uint256 value, uint256 chainID);
    event TokenOutFailed(uint256 indexed orderID, address indexed tokenAddress, address indexed user, uint256 value, uint256 chainID);

   

    
    receive () external payable {
        coinIn();
    }
    
    function coinIn() public payable returns(bool){
        orderID++;
        emit CoinIn(orderID, msg.sender, msg.value);
        return true;
    }
    
    function coinOut(address user, uint256 amount, uint256 _orderID) external onlySigner returns(bool){
        if(address(this).balance >= amount){
            payable(user).transfer(amount);
            emit CoinOut(_orderID, user, amount);
        }
        else{
            emit CoinOutFailed(_orderID, user, amount);
        }
        return true;
    }
    
    
    function tokenIn(address tokenAddress, uint256 tokenAmount, uint256 chainID) external returns(bool){
        orderID++;
        ERC20Essential(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        emit TokenIn(orderID, tokenAddress, msg.sender, tokenAmount, chainID);
        return true;
    }
    
    
    function tokenOut(address tokenAddress, address user, uint256 tokenAmount, uint256 _orderID, uint256 chainID) external onlySigner returns(bool){
        
        if(ERC20Essential(tokenAddress).balanceOf(address(this)) >= tokenAmount){
            ERC20Essential(tokenAddress).transfer(user, tokenAmount);
            emit TokenOut(_orderID, tokenAddress, user, tokenAmount, chainID);
        }
        else{
            emit TokenOutFailed(_orderID, tokenAddress, user, tokenAmount, chainID);
        }
        return true;
    }

   


}