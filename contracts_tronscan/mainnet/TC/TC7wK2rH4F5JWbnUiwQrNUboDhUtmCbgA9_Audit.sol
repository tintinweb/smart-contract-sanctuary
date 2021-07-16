//SourceUnit: Audit.sol

pragma solidity ^0.5.8;
import "./lib.sol";
contract Audit is TRC20, TRC20Detailed {
  using SafeTRC20 for ITRC20;
  using Address for address;
  using SafeMath for uint;
  uint256 maxSupply = 1000000e6;
  uint private tokenPrice = 10e6;
  address public tokenContractAddress;
  address public governance;
  address public defiAuditsToken;
  mapping (address => bool) public minters;
    address payable public ownerC;
    uint256 public auditCost = 500e6;
    uint256 numberOfTokens = 0;
    uint256 public minBid = 10;
    mapping(address => bool) public whitelisted;
    address[] public whitelistAddress; 
    uint256 public  latestContractId;
    uint256 public constant CONTRACT_CODE = 1000; 
    struct Bid {
        address requestedBy;
        uint auditToken;
        uint256 timesRequested;
    }
    struct AuditRequest {
        address contractAddress;
        address requestedBy;
        uint auditToken;
        uint256 totalAuditTokens;
        uint timesRequested;
        bool isAudited ; 
        bool isAccepted; 
        bool isVerified ; 
        address verifiedby;
        uint256 bidCount;
         Bid[] bids;
    }

    mapping(uint256 => AuditRequest) public currentAuditRequest;
    mapping(address => uint256) public contractAddressRequest;
    AuditRequest[] pendingList;
    constructor (address _tokenContractAddress) public TRC20Detailed("Audit", "AUDIT", 6) {
        tokenContractAddress = address(this);
        defiAuditsToken = _tokenContractAddress;
        ownerC = msg.sender;
        governance = msg.sender;
        whitelistAddress.push(ownerC);
        _mint(msg.sender, 50000e6);
        latestContractId= CONTRACT_CODE;
        whitelisted[ownerC] = true;
    }
    function requestAudit(uint256 amount, address _contractAddress) public  returns(uint256 contractId){
        require(amount >= auditCost,"Minimum amount not met");

         for(uint8 i = 0; i < pendingList.length; i++) {
             require(pendingList[i].contractAddress != _contractAddress, "Contract is already submitted for audit");
         }
            _burn(msg.sender,amount);
            latestContractId= latestContractId.add(1);
            currentAuditRequest[latestContractId].contractAddress = _contractAddress;
            currentAuditRequest[latestContractId].requestedBy = msg.sender;
            currentAuditRequest[latestContractId].auditToken = amount;
            currentAuditRequest[latestContractId].totalAuditTokens = amount;
            currentAuditRequest[latestContractId].timesRequested = block.timestamp;
            currentAuditRequest[latestContractId].isAudited = false;
            currentAuditRequest[latestContractId].isVerified = false;
            currentAuditRequest[latestContractId].isAccepted = false;
            currentAuditRequest[latestContractId].bidCount = 1;
            currentAuditRequest[latestContractId].bids.push(Bid({
                    requestedBy: msg.sender,
                    auditToken: amount,
                    timesRequested: block.timestamp
                }));

            pendingList.push(currentAuditRequest[latestContractId]);
            contractAddressRequest[_contractAddress] = latestContractId;

            return(latestContractId);
    }

    function addPriority(uint256 amount, uint256 contractId) public{
        require(amount >= minBid, "Minimum amount not met");
        uint256 bidCount = currentAuditRequest[contractId].bidCount;
        AuditRequest storage audit = currentAuditRequest[contractId];
        require(audit.isAccepted, "Audit is not accepted yet");
        _burn(msg.sender,amount);
            
             for(uint8 j = 0; j < pendingList.length; j++) {
                if(pendingList[j].contractAddress == audit.contractAddress){
                     pendingList[j].bidCount = pendingList[j].bidCount.add(1);
                    pendingList[j].totalAuditTokens = pendingList[j].totalAuditTokens.add(amount);
                }
            }

            currentAuditRequest[contractId].bids.push(Bid({
                        requestedBy: msg.sender,
                        auditToken: amount,
                        timesRequested: block.timestamp
                    }));
            currentAuditRequest[contractId].bidCount = audit.bidCount.add(1);
            currentAuditRequest[contractId].totalAuditTokens = currentAuditRequest[contractId].totalAuditTokens.add(amount);
    }
    
    function acceptAuditRequest(bool isAccepted, uint256 contractId) public{
        require(msg.sender == ownerC ,"Only owner can accept/reject audit request");
        AuditRequest storage audit = currentAuditRequest[contractId];
        currentAuditRequest[contractId].isAccepted = isAccepted;
        
          for(uint8 j = 0; j < pendingList.length; j++) {
                if(pendingList[j].contractAddress == audit.contractAddress){
                    pendingList[j].isAccepted = isAccepted;
                }
          }

        if(!isAccepted){
            _mint(audit.requestedBy, audit.auditToken);
             for(uint8 i = 0; i < pendingList.length; i++) {
                if(pendingList[i].contractAddress != audit.contractAddress){
                    removeDataFromList(i);
                    break;
                }
        }
        }
    }
    
     function verifyAudit(bool isVerified, uint256 contractId) public{
        require(whitelisted[msg.sender],"Not Authorized to verify");
         AuditRequest storage audit = currentAuditRequest[contractId];
         require(audit.isAccepted == true || audit.isAudited == true ,"Contract is not Accepted By Admin");
         // need to check conditions for the isAudited & isAccepted
         for(uint8 j = 0; j < pendingList.length; j++) {
                if(pendingList[j].contractAddress == audit.contractAddress){
                    pendingList[j].isVerified = isVerified;
                }
          }
         currentAuditRequest[contractId].isVerified = isVerified;
    }
    
    
   function markAsAudited(bool isAudited, uint256 contractId) public{
        require(msg.sender == ownerC,"Only owner can accept/reject audit request");
         AuditRequest storage audit = currentAuditRequest[contractId];
         currentAuditRequest[contractId].isAudited = isAudited;
        for(uint8 j = 0; j < pendingList.length; j++) {
                if(pendingList[j].contractAddress == audit.contractAddress){
                    pendingList[j].isAudited = isAudited;
                }
          }

         for(uint8 i = 0; i < pendingList.length; i++) {
                if(pendingList[i].contractAddress != audit.contractAddress){
                    removeDataFromList(i);
                    break;
                }
        }
    }


    function getContractBidList(uint256 contractId) public returns(address[] memory requestedBy,uint[] memory auditToken,uint256[] memory timesRequested){
            AuditRequest storage audit = currentAuditRequest[contractId];
            address[] memory _requestedBya = new address[](audit.bids.length);
            uint[] memory _auditTokena = new uint[](audit.bids.length);
            uint256[] memory _timesRequesteda = new uint256[](audit.bids.length);

            for(uint256 i = 0; i < audit.bids.length; i++) {
                _requestedBya[i] = audit.bids[i].requestedBy;
                _auditTokena[i] = audit.bids[i].auditToken;
                _timesRequesteda[i] = audit.bids[i].timesRequested;
            }
         return (
            _requestedBya,
            _auditTokena,
            _timesRequesteda
         );
     }


    function getContractValue(uint256 contractId) view external returns( address contractAddress,address requestedBy,
        uint auditToken,
        uint256 totalAuditTokens,
        uint timesRequested,
        bool isAudited ,
        bool isAccepted, 
        bool isVerified , 
        address verifiedby,
        uint256 bidCount
        ) {
        AuditRequest storage audit = currentAuditRequest[contractId];
    
 
        return (
            audit.contractAddress,
            audit.requestedBy,
            audit.auditToken,
            audit.totalAuditTokens,
            audit.timesRequested,
            audit.isAudited,
            audit.isAccepted,
            audit.isVerified,
            audit.verifiedby,
            audit.bidCount
        );
    }
    function getContractIdByAddress(address _addr) public view returns (uint256) {
        return contractAddressRequest[_addr];
    }
    function checkVerifiedContract(uint256 contractId) public view returns(bool){
        return currentAuditRequest[contractId].isVerified;
    }

    function getPendingAuditContract() public view returns(
        address[] memory contractAddress,
        address[] memory requestedBy,
        uint[] memory auditToken,
        uint256[] memory totalAuditTokens,
        uint[] memory timesRequested,
        bool[] memory isAccepted,
        uint256[] memory bidCount
        ){
        
        require(whitelisted[msg.sender],"Not Authorized to verify");
        
         address[] memory _contractAddress = new address[](pendingList.length);
         address[] memory _requestedBy = new address[](pendingList.length);
         uint[] memory _auditToken = new uint[](pendingList.length);
         uint256[] memory _totalAuditTokens = new uint256[](pendingList.length);
         uint[] memory _timesRequested = new uint[](pendingList.length);
         bool[] memory _isAccepted = new bool[](pendingList.length);
         uint256[] memory _bidCount = new uint256[](pendingList.length);

        for(uint256 i = 0; i < pendingList.length; i++) {
              _requestedBy[i] = pendingList[i].requestedBy;
              _contractAddress[i] = pendingList[i].contractAddress;
              _auditToken[i] = pendingList[i].auditToken;
              _totalAuditTokens[i] = pendingList[i].totalAuditTokens;
              _timesRequested[i] = pendingList[i].timesRequested;
              _isAccepted[i] = pendingList[i].isAccepted;
              _bidCount[i] = pendingList[i].bidCount;
        }

        return(
            _contractAddress,
            _requestedBy,
            _auditToken,
            _totalAuditTokens,
            _timesRequested,
            _isAccepted,
            _bidCount
        );
         
    }

    function addWhitelist(address addr) public returns(bool){
        require(msg.sender == ownerC, "unauthorized call");
        whitelisted[addr] = true;
        whitelistAddress.push(addr);
        return true;
    }

    function removeWhitelist(address addr) public returns(bool){
        require(msg.sender == ownerC, "unauthorized call");
        whitelisted[addr] = false;
         for(uint8 i = 0; i < whitelistAddress.length; i++) {
                if(whitelistAddress[i] == addr){
                    removeDataFromWhiteList(i);
                    break;
                }
            }
        return true;
    }

    function removeDataFromWhiteList(uint8 index) internal returns(bool){
        if (index >= whitelistAddress.length) return false;
        for (uint i = index; i<whitelistAddress.length-1; i++){
            whitelistAddress[i] = whitelistAddress[i+1];
        }
        delete whitelistAddress[whitelistAddress.length-1];
        whitelistAddress.length--;
        return true;
    }

    function removeDataFromList(uint8 index) internal returns(bool){
        if (index >= pendingList.length) return false;
        for (uint i = index; i<pendingList.length-1; i++){
            pendingList[i] = pendingList[i+1];
        }
        delete pendingList[pendingList.length-1];
        pendingList.length--;
        return true;
    }


   function getNewTokens(uint256 tokensToDistribute, address tobeSent) public {
         require(msg.sender == ownerC,"Not Authorized to mint");
         require(maxSupply > totalSupply(), "All tokens minted");
         uint256 remaining = maxSupply.sub(totalSupply());
         require(tokensToDistribute <= remaining );
         _mint(tobeSent,tokensToDistribute);         
    }

    function changeMaxSupply(uint256 newSupply) public {
        require(msg.sender == ownerC, "Not authorized");
        maxSupply = newSupply;
    }

    function changeAuditCost(uint256 newAuditCost) public {
        require(msg.sender == ownerC, "Not authorized");
        auditCost = newAuditCost;
    }

    function changeBid(uint256 newMinBid) public {
        require(msg.sender == ownerC, "Not authorized");
        minBid = newMinBid;
    }

    function changetokenPrice (uint256 newtokenPrice) public{
        require(msg.sender == ownerC, "Not authorized");
        tokenPrice = newtokenPrice;
    }

  
    function buyAuditTokensWithTRX(address referral) public payable {
        require(msg.value >= (tokenPrice.div(1e6)), "Value less than minimum purchase");
        require(whitelisted[referral],"Not whitelisted");
        numberOfTokens = msg.value.div(auditCost).mul(1e6);
        uint256 remaining = maxSupply.sub(totalSupply());
        require(numberOfTokens <= remaining , "Max supply reached");
        ownerC.transfer(msg.value.div(10).mul(9));
        // address(uint160(referral)).transfer(msg.value.div(1).mul(10));
        address upline = referral;
        address(uint160(upline)).transfer(msg.value.div(10).mul(1));
        _mint(referral, numberOfTokens.mul(2).div(100));
        _mint(msg.sender, numberOfTokens);
    }
    
    function buyAuditTokensWithDA(uint256 amount) public {
         require(amount >= 1);
         ITRC20 tokencontract = ITRC20(tokenContractAddress);
         if(tokencontract.transferFrom(msg.sender,ownerC,amount)){
             _mint(msg.sender, amount.mul(100));
         }
    }

    
}

//SourceUnit: lib.sol

pragma solidity ^0.5.8;
interface ITRC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract TRC20 is Context, ITRC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0));
        require(_balances[account] >= amount, "insufficient balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TRC20Detailed is ITRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeTRC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}