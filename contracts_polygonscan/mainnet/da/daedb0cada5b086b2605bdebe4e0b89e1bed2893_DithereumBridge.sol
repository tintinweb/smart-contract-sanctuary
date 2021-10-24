/**
 *Submitted for verification at polygonscan.com on 2021-10-23
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
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
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
    
contract DithereumBridge is owned {
    
    

    // This generates a public event of coin received by contract
    event CoinIn(address indexed user, uint256 value);
    event CoinOut(address indexed user, uint256 value);
    event CoinOutFailed(address indexed user, uint256 value);
    event TokenIn(address indexed tokenAddress, address indexed user, uint256 value);
    event TokenOut(address indexed tokenAddress, address indexed user, uint256 value);
    event TokenOutFailed(address indexed tokenAddress, address indexed user, uint256 value);

   

    
    receive () external payable {
        coinIn();
    }
    
    function coinIn() public payable returns(bool){
        emit CoinIn(msg.sender, msg.value);
        return true;
    }
    
    function coinOut(address user, uint256 amount) external onlySigner returns(bool){
        if(address(this).balance >= amount){
            payable(user).transfer(amount);
            emit CoinOut(user, amount);
        }
        else{
            emit CoinOutFailed(user, amount);
        }
        return true;
    }
    
    
    function tokenIn(address tokenAddress, uint256 tokenAmount) external returns(bool){
        ERC20Essential(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        emit TokenIn(tokenAddress, msg.sender, tokenAmount);
        return true;
    }
    
    
    function tokenOut(address tokenAddress, address user, uint256 tokenAmount) external onlySigner returns(bool){
        
        if(ERC20Essential(tokenAddress).balanceOf(address(this)) >= tokenAmount){
            ERC20Essential(tokenAddress).transfer(user, tokenAmount);
            emit TokenOut(tokenAddress, user, tokenAmount);
        }
        else{
            emit TokenOutFailed(tokenAddress, user, tokenAmount);
        }
        return true;
    }

   


}