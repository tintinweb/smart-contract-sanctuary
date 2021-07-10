/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
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


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract ERC20 is Context, IERC20, IERC20Metadata, Ownable{
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 internal _decimals;


    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract ERC20Token is ERC20("Exclusive Network", "Exc", 18) {
    
    // Declaring fund receiver
    address private  fund_receiver = payable(0x17F6AD8Ef982297579C203069C1DbfFE4348c372);
    /*
    * **** above are the address for the fund receiver wallet for the presale.
    * ________________________________________________________________________________________________________________________________
    */
    
    
    uint256 public tokenRate = 100000000000000000;
     
    // Declaring the roles and lock time for the wallets.
    struct RolesLocked {
       address address_;
       uint8 percentLocked;
       uint256 timeLocked;
    }
    
    mapping (string => RolesLocked) private roles;
    
    
    
    // unlocked declaration
    struct RolesUnlocked {
        address address_;
        uint8 percent;
    }
    // 
    
    /*
    * **** below are the address for the unlocked wallet.
    * __________________________________________________________________________________________________________________________________
    */
    
    RolesUnlocked public public_sale_unlocked = RolesUnlocked(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 25); // public sale address will mint with 25 % of totalSupply
    RolesUnlocked public exchanges_and_liquidity_unlocked = RolesUnlocked(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 5); // exchanges_and_liquidity address will mint with 5 % of totalSupply
    RolesUnlocked public marketing_unlocked = RolesUnlocked(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c, 10); // marking address will mint with 10 % of totalSupply
    RolesUnlocked public presale_unlocked = RolesUnlocked(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 25); // marking address will mint with 10 % of totalSupply

    /*
    * **** above are the address for the unlocked wallet.
    * __________________________________________________________________________________________________________________________________
    */
    
    // fund collect for the presale.
    uint256 public presale_fund;
    
    // declaration of requirements for the presale.
    bool public isPresaleStarted = false;

    
    constructor(){
        // filling the roles address and locked timeline.
        
        /*
        * **** below are the address for the locked wallets.
        * ____________________________________________________________________________________________________________________________________
        */
        
        roles["partnership_locked_address"] = RolesLocked(0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B, 15,   block.timestamp + 63072000); // blocktime + 2 years of time. with 15%
        roles["team_locked_address"] = RolesLocked(0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678, 10,   block.timestamp + 63072000 ); // blocktime + 2 year of time. with 10%
        roles["advisors_locked_address"] = RolesLocked(0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7, 5,   block.timestamp + 31536000); // blocktime + 1 year with 5 %. 
        roles["Reserve_locked_address"] = RolesLocked(0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C, 5, block.timestamp + 31536000); // blocktime + 1 year with 5 %.
        
        /*
        * **** above are the address for the locked wallets.
        * _____________________________________________________________________________________________________________________________________
        */
        
        // minting the tokens to as per the tokenomics.
        uint256 supply = 2 * (10**9) * (10**18);
        
        _mint(roles['partnership_locked_address'].address_, (roles['partnership_locked_address'].percentLocked*supply)/100); // Minting to the partnership_locked_address.
        _mint(roles['team_locked_address'].address_, (roles['team_locked_address'].percentLocked*supply)/100); // Minting to the Team_locked_address.
        _mint(roles['advisors_locked_address'].address_, (roles['advisors_locked_address'].percentLocked*supply)/100); // Minting to the advisors_locked_address.
        _mint(roles['Reserve_locked_address'].address_, (roles['Reserve_locked_address'].percentLocked*supply)/100); // Minting to the Reserve_locked_address.
        
        // minting to the unlocked address.
        _mint(public_sale_unlocked.address_, (public_sale_unlocked.percent*supply)/100); // Minting to the public_sale_unlocked.
        _mint(exchanges_and_liquidity_unlocked.address_, (exchanges_and_liquidity_unlocked.percent*supply)/100); // Minting to the exchanges_and_liquidity_unlocked.
        _mint(marketing_unlocked.address_, (marketing_unlocked.percent*supply)/100); // Minting to the marketing_unlocked.
        
        // setting the fund for the presale. 25% will be locked for the presale.
        _mint(presale_unlocked.address_, (presale_unlocked.percent*supply)/100); // Minting to the marketing_unlocked.
        presale_fund = (20*((25*supply)/100)/100);
        _approve(presale_unlocked.address_, address(this), (presale_unlocked.percent*supply)/100);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) override internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        // checking the locked events.
        sender==roles['partnership_locked_address'].address_? 
        require(roles['partnership_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for partnership_locked_address."):
        
        sender==roles['team_locked_address'].address_? 
        require(roles['team_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for team_locked_address."):
        
        sender==roles['advisors_locked_address'].address_? 
        require(roles['advisors_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for advisors_locked_address."):
        
        sender==roles['Reserve_locked_address'].address_? 
        require(roles['Reserve_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for Reserve_locked_address."): ();
        
        
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function startPresale() public onlyOwner {
        isPresaleStarted = true;        
    }
    
    function endPresale() public onlyOwner {
        isPresaleStarted = false;
    }
    
    
    function buyToken() public payable {
        require(msg.sender!=address(0), "ERC20: zero address cannot buy tokens");
        require(msg.value> 0, "ERC20: value is Zero");
        
        uint256 transferAmount = (msg.value*tokenRate)/(10**18);
        require(presale_fund >= transferAmount, "ERC20: Presale fund remaining not meeting the requirements.");
        
        _transfer(presale_unlocked.address_, msg.sender, (20*transferAmount/100));
        presale_fund -= (20*transferAmount/100);
        
        payable(fund_receiver).transfer(msg.value);
        
    }
    
    function setTokenRate(uint256 _no_of_token_per_eth_withDecimals) public onlyOwner {
        //  Note: Rate = number of tokens per eth * token decimals. 
        tokenRate = _no_of_token_per_eth_withDecimals;
    }
    
    function Airdrop(address[] memory _airdropReceivers, uint256[] memory _amountWithDecimals) public  {
        // Please check the allowance from the funded wallet before calling the function.
        // second argument is the array of the address of the airdrop receivers.
        for(uint i=0; i<_airdropReceivers.length; i++){
            transferFrom(msg.sender, _airdropReceivers[i], _amountWithDecimals[i]);
        }
    }
    
    function get_partnership_locked_details() view public returns(RolesLocked memory){
        return roles["partnership_locked_address"];
    }
    
    function get_team_locked_details() view public returns(RolesLocked memory){
        return roles["team_locked_address"];
    }
    
    function get_advisor_locked_details() view public returns(RolesLocked memory){
        return roles["advisors_locked_address"];
    }
    
    function get_reserved_locked_details() view public returns(RolesLocked memory){
        return roles["Reserve_locked_address"];
    }
    
}