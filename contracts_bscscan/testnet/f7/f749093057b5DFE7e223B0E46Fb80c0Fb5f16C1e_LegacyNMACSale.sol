/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-11
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



contract LegacyNMACSale is Ownable  {
    
    bool public saleOpen;
    bool public tokensWithdrawal;
    uint256 public price;
    
    address[] public team;
    
    mapping ( address => bool ) public WhiteList;
    address payable public teamWallet = payable(0x242bF9b7238c09853e440DCE270EeDFaE94A467A);
    address public EmergencyAddress;

    event AddressWhitelisted ( address _address );
    event NMAC_Purchased ( address _purchaser, uint _bnbamount, uint _tokenamount );
    event Disbursement ( address _receipent , uint256 _disbursementnumber , uint256 _disbursemenamount );
    
    mapping ( address => Sale ) public Sales;
    
    struct Sale {
        
       
        uint256 bnbSpent;
        uint256 tokensPurchased;
        uint256 timePurchased;
        uint256 numberofpaymentsreceived;
        uint256 lastpaymentblocktime;
        uint256 disbursementamount;
    }
    
    uint256 public DisbursementRequestCount;
    mapping ( uint256 => DisbursementRequest ) public DisbursementRequests;
    
    
    struct DisbursementRequest {
        address owner;
        uint256 amount;
        
    }
    
    
    constructor() {
        EmergencyAddress = msg.sender;
        price = 100;
        team = [msg.sender, 0xF04e9542121C7b2b7D534Ef5291b44d2a8986520, 0x943Ea63d355C1FDCAB585C9705Ba9Ae596fb1D87];
        
    }
    
    function purchaseNMAC () public payable {
        require ( saleOpen , "Sale not open");
        require ( !tokensWithdrawal, "Withdrawal open" );
        require ( WhiteList[msg.sender ], "Address not whitelisted ");
        require ( msg.value >= 500000000000000000, "Minimum .25 BNB");
        uint256 _total = msg.value + Sales[msg.sender].bnbSpent;
        require ( _total <= 4000000000000000000, "Too Much" );
        uint256 _amount = msg.value * price;
       
        Sales[msg.sender].bnbSpent  += msg.value;
        Sales[msg.sender].tokensPurchased += _amount;
        Sales[msg.sender].disbursementamount = Sales[msg.sender].tokensPurchased/4;
        emit NMAC_Purchased ( msg.sender, msg.value, _amount );
    }
    
    function whitelistAddress ( address _address ) public onlyTeam {
        WhiteList[ _address ] = true;
    }
    
    function whitelistAddressArray ( address [] memory _address ) public onlyTeam {
        
        for ( uint256 x=0; x< _address.length ; x++ ){
            WhiteList[_address[x]] = true;
            
        }
        
    }
    
    
    function unWhitelistAddress ( address _address ) public onlyTeam {
        WhiteList[ _address ] = false;
    }
    
    function setTeam ( address[] memory _team ) public onlyOwner {
        team = _team;
    }
    
    function toggleSale () public onlyOwner {
        saleOpen = !saleOpen;
    }
    
    function toggleWithdrawal () public onlyOwner {
        require ( !saleOpen, "sale still open" );
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
         require ( block.timestamp > Sales[msg.sender].lastpaymentblocktime , "NMAC not available yet" );
         require ( Sales[msg.sender].disbursementamount >0  , "No Disbursements available" );
         Sales[msg.sender].numberofpaymentsreceived++;
         Sales[msg.sender].lastpaymentblocktime = block.timestamp + 30 days;
         
         DisbursementRequestCount++;
         DisbursementRequests[DisbursementRequestCount].owner = msg.sender;
         DisbursementRequests[DisbursementRequestCount].amount = Sales[msg.sender].disbursementamount;
        
        
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