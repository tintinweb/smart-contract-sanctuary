/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol



pragma solidity ^0.8.9;



interface ERC20 {
 
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File: contracts\ComicMinter.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



contract MetaPresale2 is Ownable  {
    
    bool public saleOpen;
    bool public tokensWithdrawal;
    uint256 public tokensperbnb;
    bool public onlyWhitelisted = true;

    address[] public team;
    
    mapping ( address => bool ) public WhiteList;
    address payable public teamWallet = payable(0x9EC628818D299d70532801480722B86F6683a562);
    address public EmergencyAddress;

    event AddressWhitelisted ( address _address );
    event Purchased ( address _purchaser, uint _bnbamount, uint _tokenamount );
    event Disbursement ( address _receipent , uint256 _disbursementnumber , uint256 _disbursemenamount );
    
    mapping ( address => Sale ) public Sales;
    
    uint256 public tokensPurchased;
    uint256 public bnbRaised;
    uint256 public hardCap = 400 * 10 ** 18;
    
    uint256 public bridgedAmountRequested;
    
    uint256 public maxTokensForSale;   
       
    struct Sale {
        
       
        uint256 bnbSpent;
        uint256 tokensPurchased;
      
        uint256 numberofpaymentsreceived;
        uint256 lastpaymentblocktime;
        uint256 disbursementamount;
        uint256 balanceleft;
    }
    
    uint256 public DisbursementRequestCount;
    mapping ( uint256 => DisbursementRequest ) public DisbursementRequests;
    
    
    struct DisbursementRequest {
        address owner;
        uint256 amount;
        
    }
    
    
    constructor() {
        EmergencyAddress = msg.sender;
        tokensperbnb = 0;
        team = [msg.sender, 0xF04e9542121C7b2b7D534Ef5291b44d2a8986520];
        maxTokensForSale = 333000000000 * 10 ** 18;
    }
    
    function purchase () public payable {
        require ( saleOpen , "Sale not open" );
        require ( !tokensWithdrawal, "Withdrawal open" );
        require ( msg.value >= 250000000000000000, "Minimum 0.25 BNB");
        uint256 _total = msg.value + Sales[msg.sender].bnbSpent;
        require ( _total <= 2000000000000000000, "Maximum 2.0 BNB" );
        uint256 _amount = msg.value * tokensperbnb;
        require ( bnbRaised <= hardCap );

        if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require ( WhiteList[msg.sender ], "Address not whitelisted ");
            }
        }
        bnbRaised += msg.value;       
        
        //require (tokensPurchased <= maxTokensForSale, "Max tokens sold" );
        
        Sales[msg.sender].bnbSpent  += msg.value;
        Sales[msg.sender].tokensPurchased += _amount;
        Sales[msg.sender].disbursementamount = Sales[msg.sender].tokensPurchased/4;
        Sales[msg.sender].balanceleft  = Sales[msg.sender].tokensPurchased;
        
        emit Purchased ( msg.sender, msg.value, _amount );
    }
    
    function setMaximumTokensforSale ( uint256 _amount ) public onlyOwner {
        
        maxTokensForSale = _amount;
    }
    
    
    
    function whitelistAddress ( address _address ) public onlyTeam {
        WhiteList[ _address ] = true;
    }
    
    function whitelistAddressArray ( address [] memory _address ) public onlyTeam {
        
        for ( uint256 x=0; x< _address.length ; x++ ){
            WhiteList[_address[x]] = true;
            
        }
        
    }
    
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
    function unWhitelistAddress ( address _address ) public onlyTeam {
        WhiteList[ _address ] = false;
    }
    
    
    function setTokensPerBNB ( uint256 _tokensperbnb ) public onlyTeam {
        tokensperbnb = _tokensperbnb;
    }
    
    function setTeam ( address[] memory _team ) public onlyOwner {
        team = _team;
    }

    function setHardCap ( uint256 _hardCap ) public onlyOwner {
        hardCap = _hardCap;
    }
    
    function toggleSale () public onlyTeam {
        saleOpen = !saleOpen;
    }
    
    function toggleWithdrawal () public onlyTeam {
        require ( !saleOpen, "sale still open" );
        require ( tokensperbnb > 1 , "Please set Tokens Per BNB" );
        tokensWithdrawal = !tokensWithdrawal;
    }

    function withdrawToken ( address _tokenaddress ) public OnlyEmergency {
      ERC20 _token = ERC20 ( _tokenaddress );
      _token.transfer ( msg.sender, _token.balanceOf(address(this)) );
    }
    
    function withdrawBNB () public OnlyEmergency {
       payable(msg.sender).transfer( address(this).balance );
    }
    
    function receiveTokens() public  {
         require ( tokensWithdrawal , "Withdrawal not availble");
         require ( Sales[msg.sender].numberofpaymentsreceived < 4 , "Vested amount already disbursed" );
         require ( block.timestamp > Sales[msg.sender].lastpaymentblocktime , "Presale not available yet" );
         
         Sales[msg.sender].numberofpaymentsreceived++;
         Sales[msg.sender].lastpaymentblocktime = block.timestamp + 1 days; // change to 30 days
         
         
         
         if ( Sales[msg.sender].tokensPurchased == 0 ) {
            Sales[msg.sender].tokensPurchased = tokensperbnb * 1 * 10 ** 18;
            Sales[msg.sender].disbursementamount =  Sales[msg.sender].tokensPurchased / 4;
            Sales[msg.sender].balanceleft = Sales[msg.sender].tokensPurchased;
         }
         
         Sales[msg.sender].balanceleft -=  Sales[msg.sender].disbursementamount;
         
         DisbursementRequestCount++;
         DisbursementRequests[DisbursementRequestCount].owner = msg.sender;
         DisbursementRequests[DisbursementRequestCount].amount = Sales[msg.sender].disbursementamount;
         
         bridgedAmountRequested += Sales[msg.sender].disbursementamount;
         
        
        
         emit Disbursement ( msg.sender, Sales[msg.sender].numberofpaymentsreceived, Sales[msg.sender].disbursementamount );
    }
  
    modifier OnlyEmergency() {
        require( msg.sender == EmergencyAddress, "Emergency Only");
        _;
    }
    
    
    modifier onlyTeam() {
        bool check;
        for ( uint8 x = 0; x < team.length; x++ ){
            if ( team[x] == msg.sender ) check = true;
        }
        require( check == true, "Team Only");
        _;
    }
}