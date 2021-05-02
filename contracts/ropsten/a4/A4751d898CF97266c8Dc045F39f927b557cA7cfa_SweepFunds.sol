//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0; //declare solidity version to use

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract SweepFunds {
    
    //address declaration
    address payable public merchant;
    address payable public admin ;
    
    //Events Logging
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event setSeepingWalletEvent(address indexed merchant,uint date);
    event LogForwardedEther(uint total, address indexed merchant, uint merchVal);
    event LogForwardedToken(uint total, address indexed merchant, uint merchVal,  address indexed token);
    event acceptedToken(address indexed user,uint amount,address indexed token);
    event acceptedEth(address indexed user,uint amount);
    
    //modifier
    
    modifier onlyOwner() {
        require(msg.sender==admin, "Ownable: caller is not the owner");
        _;
    }

    //Fallback function; Gets called when Ether is deposited, and forwards it to merchant and admin
    receive() external payable {
        transferFunds(msg.value);
    }
    
    constructor(address payable _admin){
        admin=_admin;
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(admin, newOwner);
        admin = newOwner;
    }
    
    //!st user have to approvetheir tokens to this contract Address
    function acceptToken(address _token,uint256 _value) public payable{
        uint256 TokenBalance = ERC20(_token).balanceOf(msg.sender);
        require(TokenBalance>_value,"Not enough balance ");
        ERC20(_token).transferFrom(msg.sender,address(this),_value);
        emit acceptedToken(msg.sender,_value,_token);
    }
    function acceptEth()public payable{
        require(msg.value>0,"Must provide some eth");
        emit acceptedEth(msg.sender,msg.value);
    }
    
    function setSeepingWallet(address payable _merchant)public onlyOwner{
        merchant=_merchant;
        emit setSeepingWalletEvent(merchant,block.timestamp);
    }
    function sweepEther() public payable onlyOwner{
        uint ethBal = getContractBalance();
        transferFunds(ethBal);
    }
    
    //Sweep tokens method by specifying token contract address and amount.
    function sweepTokens(address _token) public onlyOwner{
        transferFunds(_token);
    }

    //General transfer funds function (Ether)
    function transferFunds(uint _value) internal {
        require(_value > 0,"Don't have enough Eth to transfer");
        
        //Perform Ether transfer method
        emit LogForwardedEther(_value, merchant, block.timestamp);
        merchant.transfer(_value );
    }
    
    //transfer funds function (Token)
    function transferFunds(address _token) internal {
        uint _value = getTokenBalance(_token);
        require(_value > 0,"Don't have enough tokens to transfer");
            
        //Perform Token transfer method
        emit LogForwardedToken(_value, merchant, block.timestamp,_token);
        ERC20(_token).transfer(merchant, _value);
    }
    
    //Get Token Balance and Contract Eth Balance
    
    function getTokenBalance(address _token) public view returns(uint){
        return ERC20(_token).balanceOf(address(this));
    }
    
    function getContractBalance()public view returns (uint){
        return address(this).balance;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}