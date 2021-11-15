// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;
import "../IERC20.sol";
import "../SafeERC20.sol";
import "../Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract Whitelist is Pausable {
  uint8 public constant version = 1;

  mapping (address => bool) private whitelistedMap;

  event Whitelisted(address indexed account, bool isWhitelisted);

  function whitelisted(address _address)
    public
    view
    returns (bool)
  {
    if (paused) {
      return false;
    }

    return whitelistedMap[_address];
  }

  function addAddress(address _address)
    public
    onlyOwner
  {
    require(whitelistedMap[_address] != true);
    whitelistedMap[_address] = true;
    emit Whitelisted(_address, true);
  }

  function removeAddress(address _address)
    public
    onlyOwner
  {
    require(whitelistedMap[_address] != false);
    whitelistedMap[_address] = false;
    emit Whitelisted(_address, false);
  }
}

pragma solidity ^0.8.4;



contract CuffiesFaucet is Whitelist {
    
     using SafeERC20 for IERC20;
    
    // The underlying cuffies of the Project
    IERC20 cuffies;
    // The underlying cuffies of the Faucet
    IERC20 busd;
    
    
    // For vesting timming calculation
    mapping(address=>uint256) public vestingFinishedAt;
    
    mapping(address=>uint256) public vested_Amount;
    
    
    uint256 public startDate = 1636584509;                  // 2021/11/10 00:00:00 UTC
    uint256 public endDate = 1636588799;                    // 2021/11/10 23:59:59 UTC
    mapping (address => bool) private whitelistedMap;
    
    // No.of cuffiess to send when requested
    uint256 public vestedCuffies_BNBprice = 83;
    //Max Cuffies allocated
    uint256 public Max_Amount = 166000 * 10**18 ;


    
     
    
    // Sets the addresses of the Owner and the underlying cuffies
    constructor (address _cuffies,address _busd) {
        cuffies = IERC20(_cuffies);
        busd = IERC20(_busd);
    }   
    

      // Verifies whether the caller has funds to buy cuffies   
       modifier costs(uint256 cost){
        require(msg.value >= cost, "insufficient funds");
        _;
    }
    
        // Sends the amount of cuffies to the caller.
    function BuymyCuffies(uint256 amount) public  {
        uint256 CuffiesAmount = amount * vestedCuffies_BNBprice;
        uint256 NewBalance= vested_Amount[msg.sender]+ CuffiesAmount;
        if (!paused){
            require( whitelistedMap[msg.sender]=true);
        }
        require( NewBalance < Max_Amount,"Max amount: 166000 cuffies per wallet");
        require(cuffies.balanceOf(address(this)) > 1,"No more cuffies :c");
        require(Max_Amount >1, "No more Vested Tokens try Unvested option");
        require(busd.balanceOf(msg.sender) >= amount , "No Busd Balance");

       Max_Amount = Max_Amount - CuffiesAmount;
        
        // Next request from the address can be made only after presale ends        
        vestingFinishedAt[msg.sender] = endDate; 
        busd.safeTransferFrom(msg.sender, address(this), amount);
        vested_Amount[msg.sender]= NewBalance;
        
       
    }  
    
    function claimBoughtAmount() external {
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
     function setCuffiesPrice(uint256 _vestedAmount) external onlyOwner {
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
      function withdrawSome(address _receiver, uint256 _amount) external onlyOwner {
        require(busd.balanceOf(address(this)) > 0,"Insufficient Ballance");
        busd.transfer(_receiver, _amount );
    }   
    
       
}