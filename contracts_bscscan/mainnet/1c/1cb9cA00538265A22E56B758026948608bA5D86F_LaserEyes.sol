/** 
---------------------OFFICIAL---------------------
--------------------LASER EYES--------------------
MMMMMMMMMMMMMMMMmdyyso++++++ooyyhmMMMMMMMMMMMMMMMM
MMMMMMMMMMMMmyo+//////////////////+oymMMMMMMMMMMMM
MMMMMMMMMmy+//////////////////////////+ydMMMMMMMMM
MMMMMMMdo////////////////////////////////+hMMMMMMM
MMMMMmo///////o+///////////////////o///////+dMMMMM
MMMMy+////////hh+////////////////+hd/////////yMMMM
MMNo//////////hNmo//////////////omNd//////////oNMM
MMo///////////hNNNhhhhhhhhhhhhhhNNNd///////////oNM
Ms////////////hNNNNNNNNNNNNNNNNNNNNd////////////sM
m/////////////hNNNNNNNNNNNNNNNNNNNNd/////////////d
s/////////////hNNNNmmmmNNNNmmmmNNNNd/////////////s
o/////////////hNNNmh+:sdmmds//ymNNNd//////////////
//////////////hNNNNmdmmmmNmmmdmmNNNd//////////////
o/////////////hNNNN--/osyyso/-.mNNNd/////////////+
s/////////////hNNNNo          :NNNNd/////////////o
m+////////////hNNNNd          yNNNNd/////////////d
Ms///////////+dNNNNN+        :NNNNNd+///////////sM
MNo//////+oydNNNNNNNNms////odNNNNNNNNdyo+//////oNM
MMNssyhdmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmdhyssNMM
MMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMM
MMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMM
MMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMM
MMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMM
MMMMMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNNNNNNNNNNNNNNNNMMMMMMMMMMMMMMMMM
**/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;


interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
        ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @dev Role for internet link moderations  
 * Laser Eyes Project
 */
abstract contract ModeratorRole is Context {
    address private _moderator;

    event ModeratorRoleTransferred(address indexed previousModerator, address indexed newModerator);

    constructor() {
        _setModerator(_msgSender());
    }

    function moderator() public view virtual returns (address) {
        return _moderator;
    }

    modifier onlyModerator() {
        require(moderator() == _msgSender(), "Moderator: caller is not the moderator");
        _;
    }

    function renounceModerator() external virtual onlyModerator {
        _setModerator(address(0));
    }

    function transferModerator(address newModerator) public virtual onlyModerator {
        require(newModerator != address(0), "Moderator: new Moderator is the zero address");
        _setModerator(newModerator);
    }

    function _setModerator(address newModerator) private {
        address oldModerator = _moderator;
        _moderator = newModerator;
        emit ModeratorRoleTransferred(oldModerator, newModerator);
    }
}


/**
 * @dev
 * Control Proved Links for Laser Eyes Project
*/  
abstract contract TrustLink is ModeratorRole {
    using SafeMath for uint256;

    // store proved Laser Eyes Links and projects
    mapping(bytes32 => uint8) private _link2status;

    uint256 public linkCounter = 0; 

    uint8 constant private MIN_LINK_LENGTH = 2;
    uint8 constant private MAX_LINK_LENGTH = 169;

    // store official Laser Eyes Links
    string public telegram;
    string public website;
    string public twitter;
    string public medium;
    string public reddit;

    modifier approveLink(string memory _someLink) {
        // validate length input link
        require(bytes(_someLink).length > MIN_LINK_LENGTH, "Link length is less than 2 characters");
        require(bytes(_someLink).length < MAX_LINK_LENGTH, "Link length is more than 169 characters");
        _;
    }

    function updateTelegram(string memory newLink) external onlyModerator approveLink(newLink) returns(bool){
        telegram = newLink;
        return true;
    }

    function updateWebsite(string memory newLink) external onlyModerator approveLink(newLink) returns(bool){
        website = newLink;
        return true;
    }

    function updateTwitter(string memory newLink) external onlyModerator approveLink(newLink) returns(bool){
        twitter = newLink;
        return true;
    }

    function updateMedium(string memory newLink) external onlyModerator approveLink(newLink) returns(bool){
        medium = newLink;
        return true;
    }

    function updateReddit(string memory newLink) external onlyModerator approveLink(newLink) returns(bool){
        reddit = newLink;
        return true;
    }

    function addTokenLink(string memory newLink, uint8 newStatus) external onlyModerator approveLink(newLink) returns(uint){
        require(newStatus > 0, "Status must be greater than 0");
        uint _newLinkCounter = _updateTokenLink(newLink, newStatus);
        return _newLinkCounter;
    }

    function deleteTokenLink(string memory someLink) external onlyModerator approveLink(someLink) returns(uint) {
        bytes32 hashLink = keccak256(bytes(someLink));
        uint8 oldStatus = _link2status[hashLink];
        require(oldStatus != 0, "Old Status Equal To Zero - Address not exists");

        uint _newLinkCounter = _updateTokenLink(someLink, 0);

        return _newLinkCounter;
    }

    function updateTokenLink(string memory someLink, uint8 newStatus) external onlyModerator approveLink(someLink) returns(uint){
        require(newStatus > 0, "Status must be greater than 0");
        uint _newLinkCounter = _updateTokenLink(someLink, newStatus);

        return _newLinkCounter;
    }  

    function _updateTokenLink(string memory someLink, 
                                        uint8 newStatus) 
                                    private approveLink(someLink) returns(uint){
        
        bytes32 hashLink = keccak256(bytes(someLink));
        uint8 oldStatus = _link2status[hashLink];
        require(oldStatus != newStatus, "Old Status Equal to New Status");

        if (oldStatus == 0){
            // add link
            _link2status[hashLink] = newStatus;
            linkCounter = linkCounter.add(1);
            } else if ( (oldStatus > 0) && (newStatus > 0) ){
            // update link
            _link2status[hashLink] = newStatus;
            } else if ( (oldStatus > 0) && (newStatus == 0) ){
            // delete link
            delete _link2status[hashLink];
            linkCounter = linkCounter.sub(1);    
        }
  
        return linkCounter;
    }     

    function getTokenLinkStatus(string memory someLink) external view approveLink(someLink) returns(uint8){
        bytes32 hashLink = keccak256(bytes(someLink));
        uint8 oldStatus = _link2status[hashLink];

        return oldStatus;
    }  

}


/**
 * @dev Main Implementation Laser Eyes Token
 * Official token of the Laser Eyes project - a service to find profitable tokens
 *  
 */ 
contract LaserEyes is Context, IBEP20, Ownable, TrustLink {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 constant private DECIMALS = 8;
    string constant private SYMBOL = "LSR";
    string constant private NAME = "LaserEyes";
    uint256 private oneMonth;

    address public laserEyesAddress;

    constructor(address _laserEyesAddress,
                  string memory _telegram, 
                  string memory _website, 
                  string memory _twitter, 
                  string memory _medium,
                  string memory _reddit) {

        require(_laserEyesAddress != address(0), "LaserEyes Mint to Zero Address");

        telegram = _telegram;
        website = _website;
        twitter = _twitter;
        medium = _medium;
        reddit = _reddit;

        laserEyesAddress =_laserEyesAddress;
        _totalSupply = 400_000_000 * 10**8;

        _balances[msg.sender] = _totalSupply;

        uint256 halfYear = 15_778_458;
        oneMonth = block.timestamp.add(halfYear);

        emit Transfer(address(0), msg.sender, _totalSupply);

        transferModerator(_laserEyesAddress);

    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function getModerator() external view returns (address) {
        return moderator();
    }

    function decimals() external override pure returns (uint8) {
        return DECIMALS;
    }

    function symbol() external override pure returns (string memory) {
        return SYMBOL;
    }

    function name() external override pure returns (string memory) {
        return NAME;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        mint();
        return true;
    }

    function allowance(address currentOwner, address spender) external override view returns (uint256) {
        return _allowances[currentOwner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        mint();
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function mint() public returns (bool) {
        
        uint256 MonthlyMint = 2_500_000 * (10**8);
        
        if(block.timestamp >= oneMonth){
            _mint(laserEyesAddress, MonthlyMint );
            oneMonth = oneMonth.add(2_629_743);
            return true;
        } else { 
            return false; 
        }
    }

    function burn(address account, uint256 amount) external onlyOwner returns (bool) {
        _burn(account , amount);
        return true;
    }

    function updateLaserEyesAddress(address newLaserEyesAddress) external onlyOwner returns(bool){
        require(newLaserEyesAddress != address(0), "LaserEyes Mint to Zero Address");

        laserEyesAddress = newLaserEyesAddress;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        uint256 MaxSupply = 1_000_000_000 * 10**8;
        if(_totalSupply < MaxSupply){
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address currentOwner, address spender, uint256 amount) internal {
        require(currentOwner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[currentOwner][spender] = amount;
        emit Approval(currentOwner, spender, amount);
    }
}