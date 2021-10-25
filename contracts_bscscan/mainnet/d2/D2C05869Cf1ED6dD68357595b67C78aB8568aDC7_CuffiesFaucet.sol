// SPDX-License-Identifier: UNLICENSED
import "./IERC20.sol";
import "./SafeERC20.sol";

pragma solidity ^0.8.4;



contract CuffiesFaucet {
    
     using SafeERC20 for IERC20;
    
    // The underlying cuffies of the Project
    IERC20 cuffies;
    // The underlying cuffies of the Faucet
    IERC20 busd;
    // The address of the faucet owner
    address owner;
    
    // For vesting timming calculation
    mapping(address=>uint256) public vestingFinishedAt;
    
    mapping(address=>uint256) public vested_Amount;
    mapping(address=>uint256) public unvested_Amount;
    
    
    // No.of cuffiess to send when requested
    uint256 public Cuffies_BNBprice = 108;
    uint256 public vestedCuffies_BNBprice = 166;
    //Max Cuffies allocated
    uint256 public Max_Unvested = 2600000 * 10**18 ;
    uint256 public Max_Vested = 9600000 * 10**18 ;
    //Max Cuffies allocated
    uint256 public Max_Amount = 166000 * 10**18 ;


    
     
    
    // Sets the addresses of the Owner and the underlying cuffies
    constructor (address _cuffies,address _busd, address _ownerAddress) {
        cuffies = IERC20(_cuffies);
        busd = IERC20(_busd);
        owner = _ownerAddress;
    }   
    
    // Verifies whether the caller is the owner 
    modifier onlyOwner{
        require(msg.sender == owner,"FaucetError: Caller not owner");
        _;
    }
      // Verifies whether the caller has funds to buy cuffies   
       modifier costs(uint256 cost){
        require(msg.value >= cost, "insufficient funds");
        _;
    }
    
    // Sends the amount of cuffies to the caller.
    function sendmeCuffies(uint256 amount) external  {
        uint256 CuffiesAmount = amount * Cuffies_BNBprice;
        uint256 NewBalance= unvested_Amount[msg.sender]+ CuffiesAmount;
        require(NewBalance < Max_Amount,"Max amount: 166000 cuffies per wallet");
        require(cuffies.balanceOf(address(this)) > 1,"No more cuffies :c");
        require(Max_Unvested >1, "No more unvested Tokens try vested option");
       require(busd.balanceOf(msg.sender) >= amount, "No Busd Balance");
        Max_Unvested = Max_Unvested - CuffiesAmount;
        busd.safeTransferFrom(msg.sender, address(this), amount );
        cuffies.transfer(msg.sender,CuffiesAmount);
    }  
    
        // Sends the amount of cuffies to the caller.
    function VestmyCuffies(uint256 amount) public  {
        uint256 CuffiesAmount = amount * vestedCuffies_BNBprice;
        uint256 NewBalance= vested_Amount[msg.sender]+ CuffiesAmount;
        
        require( NewBalance < Max_Amount,"Max amount: 166000 cuffies per wallet");
        require(cuffies.balanceOf(address(this)) > 1,"No more cuffies :c");
        require(Max_Vested >1, "No more Vested Tokens try Unvested option");
        require(busd.balanceOf(msg.sender) >= amount , "No Busd Balance");

       Max_Vested = Max_Vested - CuffiesAmount;
        
        // Next request from the address can be made only after 60 days         
        vestingFinishedAt[msg.sender] = block.timestamp + (60 days); 
        busd.safeTransferFrom(msg.sender, address(this), amount);
        vested_Amount[msg.sender]= NewBalance;
        
       
    }  
    
    function claimVestedAmount() external {
        require(vested_Amount[msg.sender] > 0, "No Cuffies Vested");
        require(cuffies.balanceOf(address(this)) > 1,"No more cuffies :c");
        require(vestingFinishedAt[msg.sender] < block.timestamp, "Vesting Period Not finished: Try again when vesting period is over");
        cuffies.transfer(msg.sender,vested_Amount[msg.sender] );
        
    }
    
    // Updates the underlying cuffies address
     function setcuffiesAddress(address _cuffiesAddr) external onlyOwner {
        cuffies = IERC20(_cuffiesAddr);
    }    
    

        // Updates the drip rate
     function setCuffiePrice(uint256 _amount,uint256 _vestedAmount) external onlyOwner {
        Cuffies_BNBprice = _amount;
        vestedCuffies_BNBprice= _vestedAmount;
    }  
     
     
     // Allows the owner to withdraw Cuffies from the contract.
     function withdrawcuffiess(address _receiver, uint256 _amount) external onlyOwner {
        require(cuffies.balanceOf(address(this)) >= _amount,"FaucetError: Insufficient funds");
        cuffies.transfer(_receiver,_amount);
    }    
    
         // Allows the owner to withdraw ALL busd from the contract.
     function withdrawALL(address _receiver) external onlyOwner {
       uint256 balance = busd.balanceOf(address(this));
        require(busd.balanceOf(address(this)) > 0,"No more BUSD");
        busd.transfer(_receiver,balance);
    }    
       // Allows the owner to withdraw SOME busd from the contract.
      function withdrawSome(address _sender,address _receiver, uint256 _amount) external onlyOwner {
        require(busd.balanceOf(_sender) > 0,"Insufficient Ballance");
        busd.safeTransferFrom(_sender, _receiver, _amount );
    }   
    
       
}