/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: sausageinu.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

//░██████╗░█████╗░██╗░░░██╗░██████╗░█████╗░░██████╗░███████╗  ██╗███╗░░██╗██╗░░░██╗
//██╔════╝██╔══██╗██║░░░██║██╔════╝██╔══██╗██╔════╝░██╔════╝  ██║████╗░██║██║░░░██║
//╚█████╗░███████║██║░░░██║╚█████╗░███████║██║░░██╗░█████╗░░  ██║██╔██╗██║██║░░░██║
//░╚═══██╗██╔══██║██║░░░██║░╚═══██╗██╔══██║██║░░╚██╗██╔══╝░░  ██║██║╚████║██║░░░██║
//██████╔╝██║░░██║╚██████╔╝██████╔╝██║░░██║╚██████╔╝███████╗  ██║██║░╚███║╚██████╔╝
//╚═════╝░╚═╝░░╚═╝░╚═════╝░╚═════╝░╚═╝░░╚═╝░╚═════╝░╚══════╝  ╚═╝╚═╝░░╚══╝░╚═════╝░


// Welcome to Sausage Inu ! The sausage dog of the blockchain (on Binance Smart Chain) !
// Let's build a cool and nice community together !
// God Bless

// Technicals Part: 
// 10B Billion Total Supply 
// Please set slippage to 10% when you buy or sell on your DEX
// 9% Tax (3% Marketing 3% Development, 3% Burn)
// Anti-whale (Maximum 2% of max supply per wallet). 
// Note : We may disable the anti-whale option in the future. 



pragma solidity ^0.8.0;





contract ERC20 is Context, IERC20, IERC20Metadata {
    //ERC20 inherits from Context, IERC20 & IERC20Metadata
    
    //saves the balances of all token holders
    mapping(address => uint256) private _balances; 
    
    //saves the allownace of all token holders
    //an allowance is basically a loan allowing another address to use your tokens
    mapping(address => mapping(address => uint256)) private _allowances;

    //total amount of tokens
    uint256 private _totalSupply;

    //name & symbol representing the tokens
    string private _name;
    string private _symbol;
    
    address private _owner;
    
    //event to let the exterior know that tokens have been burned
    event Burn(uint256 amount);
    
    //address of tax wallets
    address private marketingWallet = 0xbb43f6305593717CbDe6b9Ed2f04058be3281bF5;
    address private devWallet = 0x62dd352e74bf6D35aa218ff0d874c12D1E78FA54;
    address private burnWallet = 0x000000000000000000000000000000000000dEaD;
    
    //address of uniswap and pancakeswap routers
    address private univ2router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private univ3router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private pancakev2router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private quickswaprouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    //variable to see if ta is activated
    bool private _toggleMWTax;
    bool private _toggleDWTax;
    bool private _toggleBWTax;
    
    
    //percentages of tax
    uint256 private _MarketingWalletTax;
    uint256 private _DevWalletTax;
    uint256 private _BurnWalletTax;
    
    //exent from paying taxes
    mapping(address => bool) noMarketingTax;
    mapping(address => bool) noDevTax;
    mapping(address => bool) noBurnTax;
    
    //stores the value of if max percent of total supply is on and the value of this max percent
    bool private _toggleMPTS;
    uint256 private _maxPercentTotalSupply;
    
    //stores the value of if max percent per tx is on and the value of this max percent
    bool private _toggleMPPT;
    uint256 private _maxPercentPerTx;
    
    //whitelist that stores accounts that dont have max percentage
    mapping(address => bool) private noMaxPercentTotalSupply;
    mapping(address => bool) private noMaxPercentPerTx;

    //when you deploy the contract you suplly these three values
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        //owner starts out with all the balance
        _balances[msg.sender] = _totalSupply;
        //the person who deploys the contract will be the initial owner
        _owner = msg.sender;
        //by default the taxes will be off
        _toggleMWTax = false;
        _toggleDWTax = false;
        _toggleBWTax = false;
        //intially the tax will be 3% each
        _MarketingWalletTax = 3;
        _DevWalletTax = 3;
        _BurnWalletTax = 3;
        //by default the max of totalSupply will be disabled
        _toggleMPTS = false;
        //be default the max percent of total supply will be 2%
        _maxPercentTotalSupply = 2;
        //by default the max per tx will be disabled
        _toggleMPPT = false;
        //be default the max percent of total supply will be 2%
        _maxPercentPerTx = 2;
        //automatically establish the wallets that dont have tax or limits
        //we first define the 5 address that we want and then tak it through a for loop
        address[8] memory addresses = [marketingWallet, devWallet, burnWallet, univ2router, univ3router, pancakev2router, quickswaprouter, _owner];
        for (uint i=1; i < addresses.length; i++) {
            noTax(addresses[i]);
            noMaxLimit(addresses[i]);
        }
    }
    
    //only allows the function to continue if the owner calls it
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    
    //only allows function to continue when transaction doesnt go over max limit
    modifier maxLimitTotalSupply(address recipient, uint256 amount) {
        if (noMaxPercentTotalSupply[recipient] == false) {
            if (_toggleMPTS == true) {
                uint256 newAmount = balanceOf(recipient) + amount;
                require(newAmount <= ((totalSupply() * _maxPercentTotalSupply) / 100), 'Recipient cannot hold this amount of tokens, surpasses max limit');
            }
        }    
        _;
    }
    
    //only allows function to continue when transaction doesnt go over max limit
    modifier maxLimitPerTx(address sender, uint256 amount) {
        if (noMaxPercentPerTx[sender] == false) {
            if (_toggleMPPT == true) {
                require(amount <= ((totalSupply() * _maxPercentPerTx) / 100), 'Cannot transfer this amount of tokens, surpasses transaction limit');
            }
        }    
        _;
    }

    //returns name
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    //returns symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    //number of decimals used for tokem
    //BE CAREFUL!!! If your token supply is 5000 and you have 3 deciamls, your token supply is actually 5
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    //returns total supply
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

  
    //sees who the owner of the contract is
    function owner() public view virtual returns(address) {
        return _owner;
    }
    
    //change the owner of the contract, only to be called by the owner
    function transferOwnership(address newOwner) public onlyOwner returns(bool) {
        _owner = newOwner;
        
        return true;
    }

    //returns balances
    function balanceOf(address account) public view virtual override returns (uint256) {
        require(account != address(0), 'Cannot acces balance of 0x0 Wallet');
        return _balances[account];
    }

    //executes a transfer between two accounts
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    //returns allowance
    function allowance(address allower, address spender) public view virtual override returns (uint256) {
        return _allowances[allower][spender];
    }

    //A address approves a certain amount of its funs to be used by another address
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //an address transfers tokens from his allowance to another address
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        //first we check that the allowance is bigger than the amount that is wanted to send
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
         //we try to execute the transfer
        _transfer(sender, recipient, amount);
        
        //unchecked means that it wont check for underflows or overflows, since we know that currentAllowance > amount, this is no problem
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    //adding more tokens to an allowance
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    //taking away tokens from an allowance
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        //must have more tokens than the amount trying to be taken away
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        
        //since we know that currentAllowance > subtracted value, this is no problem
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    //sending tokens from one address to another
    function _transfer(address sender,address recipient,uint256 amount) internal virtual maxLimitPerTx(sender, amount) maxLimitTotalSupply(recipient, amount) {
        //both have to be valid address
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //we check to see that the amount is inferior to the senders balance and then update their balances
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        //we establish the marketing tax initially for this operation to be zero
        uint256 marketingTax = 0;
        //if the marketing tax is turned on and neither the recipient nor the sender is on the tax exempt whitelist, a tax while be calculated
        if (_toggleMWTax == true && noMarketingTax[recipient] == false && noMarketingTax[sender] == false) {
            marketingTax = (amount * _MarketingWalletTax) / 100;
            _balances[marketingWallet] += marketingTax;
        }
        
        
        //we establish the dev tax initially for this operation to be zero
        uint256 devTax = 0;
        //if the dev tax is turned on and neither the recipient nor the sender is on the tax exempt whitelist, a tax while be calculated
        if (_toggleDWTax == true && noDevTax[recipient] == false && noDevTax[sender] == false) {
            devTax = (amount * _DevWalletTax) / 100;
            _balances[devWallet] += devTax;
        }
        
        //we establish the burn tax initially for this operation to be zero
        uint256 burnTax = 0;
        //if the burn tax is turned on and neither the recipient nor the sender is on the tax exempt whitelist, a tax while be calculated
        if (_toggleBWTax == true && noBurnTax[recipient] == false && noBurnTax[sender] == false) {
            burnTax = (amount * _BurnWalletTax) / 100;
            _burn(burnTax);
            _balances[burnWallet] += burnTax;
        }
        
        //since we know that senderBalance >  amount, this is no problem
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        _balances[recipient] += (amount - marketingTax - burnTax - devTax);

        //emitting an event so that the exterior can see that a transfer has taken place
        emit Transfer(sender, recipient, amount);

    }
    
    //function that updates the allowance that an address has given another address
    function _approve(address allower, address spender, uint256 amount) internal virtual {
        //both addess must be valid
        require(allower != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[allower][spender] = amount;
        //emitting an event so that the exterior can see that an allowance was created
        emit Approval(allower, spender, amount);
    }
    
    //turn on & turn off the marketingTax
    function toggleMWTax() public onlyOwner {
        //checks to see current state and goes to the other
        if (_toggleMWTax = true) {
            _toggleMWTax = false;
        }
        else {
            _toggleMWTax = true;
        }
    }
    
    
    //turn on & turn off the dev wallet tax
    function toggleDWTax() public onlyOwner {
        //checks to see current state and goes to the other
        if (_toggleDWTax = true) {
            _toggleDWTax = false;
        }
        else {
            _toggleDWTax = true;
        }
    }
    
    //turn on & turn off the burn wallet tax
    function toggleBWTax() public onlyOwner {
        //checks to see current state and goes to the other
        if (_toggleBWTax = true) {
            _toggleBWTax = false;
        }
        else {
            _toggleBWTax = true;
        }
    }
    
    //give the function a percentage and it will make it the new marketingTax
    function changeMarketingTax(uint256 _percent) public onlyOwner {
        require(_percent < 25, 'Tax Cannot be more than 25% of the transaction value');
        _MarketingWalletTax = _percent;
    }
    
    
    //give the function a percentage and it will make it the new DevTax
    function changeDevTax(uint256 _percent) public onlyOwner {
        require(_percent < 25, 'Tax Cannot be more than 25% of the transaction value');
        _DevWalletTax = _percent;
    }
    
    //give the function a percentage and it will make it the new BurnTax
    function changeBurnTax(uint256 _percent) public onlyOwner {
        require(_percent < 25, 'Tax Cannot be more than 25% of the transaction value');
        _BurnWalletTax = _percent;
    }
    
    
    //adding an address to the no marketingTax mapping so that they no longer have to pay taxes on transfers
    function addToNoMarketingTax(address newAddress) public onlyOwner {
        require(noMarketingTax[newAddress] != true, 'Address is already part of Tax Exempt List');
        
        noMarketingTax[newAddress] = true;
    }
    
    //removing an address from the no marketingTax mapping so that they no longer have to pay taxes on transfers
    function removeFromNoMarketingTax(address newAddress) public onlyOwner {
        require(noMarketingTax[newAddress] != false, 'Address is not part of Tax Exempt List');
        
        noMarketingTax[newAddress] = false;
    }
    
    //duplicate of functins above
    
    function addToNoDevTax(address newAddress) public onlyOwner {
        require(noDevTax[newAddress] != true, 'Address is already part of Tax Exempt List');
        
        noDevTax[newAddress] = true;
    }
    
    function removeFromNoDevTax(address newAddress) public onlyOwner {
        require(noDevTax[newAddress] != false, 'Address is not part of Tax Exempt List');
        
        noDevTax[newAddress] = false;
    }
    
    //duplicate of functins above
    
    function addToNoBurnTax(address newAddress) public onlyOwner {
        require(noBurnTax[newAddress] != true, 'Address is already part of Tax Exempt List');
        
        noBurnTax[newAddress] = true;
    }
    
    function removeFromNoBurnTax(address newAddress) public onlyOwner {
        require(noBurnTax[newAddress] != false, 'Address is not part of Tax Exempt List');
        
        noBurnTax[newAddress] = false;
    }
    
    //removes tokens from total supply as they have been sent to dead wallet, are not accessible
    function _burn(uint256 amount) internal {
        _totalSupply = _totalSupply - amount;
        emit Burn(amount);
    }
    
    //function to view the amount of tokens that have been burned
    function burnedTokens() public view returns(uint256) {
        return _balances[burnWallet];
    } 
    
    //functions to see that state of the taxes, on or off
    
    function MarketingTaxIsActive() public onlyOwner view returns(bool) {
        return _toggleMWTax;
    }
    
    
    function DevTaxIsActive() public onlyOwner view returns(bool) {
        return _toggleDWTax;
    }
    
    function BurnTaxIsActive() public onlyOwner view returns(bool) {
        return _toggleBWTax;
    }
    
    //functions to see the current percenatge set as tax
    function currentMarketingTax() public onlyOwner view returns(uint256) {
        return _MarketingWalletTax;
    }
    
    
    function currentDevTax() public onlyOwner view returns(uint256) {
        return _DevWalletTax;
    }
    
    function currentBurnTax() public onlyOwner view returns(uint256) {
        return _BurnWalletTax;
    }
    
    //turns max percent total supply on and off
    function toggleMaxPercentTotalSupply() public onlyOwner {
        //checks to see current state and goes to the other
        if (_toggleMPTS = true) {
            _toggleMPTS = false;
        }
        else {
            _toggleMPTS = true;
        }
    }
    
    //turns max percent per transaction on and off
    function toggleMaxPercentPerTx() public onlyOwner {
        //checks to see current state and goes to the other
        if (_toggleMPPT = true) {
            _toggleMPPT = false;
        }
        else {
            _toggleMPPT = true;
        }
    }
    
    //function to change the percentage of max holdings of token
    function changeMaxPercentTotalSupply(uint256 _percent) public onlyOwner {
        //the maximum limit we can set is 99 because you cannot transfer more than 100% of the totalSupply
        require(_percent < 100, 'Max limit cannot be greater than 100');
        _maxPercentTotalSupply = _percent;
    }
    
    //function to change max percent of total supply transfered with each transaction
    function changeMaxPercentPerTx(uint256 _percent) public onlyOwner {
        //the maximum limit we can set is 99 because you cannot transfer more than 100% of the totalSupply
        require(_percent < 100, 'Max Limit cannot be greater than 100');
        _maxPercentPerTx = _percent;
    }
    
    
    //functions to see is max percentage limits are active
    
    function MaxPercentTotalSupplyIsActive() public onlyOwner view returns(bool) {
        return _toggleMPTS;
    }
    
    function MaxPercentPerTxIsActive() public onlyOwner view returns(bool) {
        return _toggleMPPT;
    }
    
    //functions to see the current percentages limits
    
    function currentMaxPercentTotalSupply() public onlyOwner view returns(uint256) {
        return _maxPercentTotalSupply;
    }
    
    function currentMaxPercentPerTx() public onlyOwner view returns(uint256) {
        return _maxPercentPerTx;
    }
    
    //adding an address to the no marketingTax mapping so that they no longer have to pay taxes on transfers
    function addToNoMaxPercentTotalSupply(address newAddress) public onlyOwner {
        require(noMaxPercentTotalSupply[newAddress] != true, 'Address is already part of Percent Limit Exempt List');
        
        noMaxPercentTotalSupply[newAddress] = true;
    }
    
    //removing an address from the no marketingTax mapping so that they no longer have to pay taxes on transfers
    function removeFromNoMaxPercentTotalSupply(address newAddress) public onlyOwner {
        require(noMaxPercentTotalSupply[newAddress] != false, 'Address is already part of Percent Limit Exempt List');
        
        noMaxPercentTotalSupply[newAddress] = false;
    }
    
    //duplicate of functins above
    
    function addToNoMaxPercentPerTx(address newAddress) public onlyOwner {
        require(noMaxPercentPerTx[newAddress] != true, 'Address is already part of Percent Limit Exempt List');
        
        noMaxPercentPerTx[newAddress] = true;
    }
    
    function removeFromNoMaxPercentPerTx(address newAddress) public onlyOwner {
        require(noMaxPercentPerTx[newAddress] != false, 'Address is already part of Percent Limit Exempt List');
        
        noMaxPercentPerTx[newAddress] = false;
    }
    
    function noMaxLimit(address newAddress) public onlyOwner returns(bool) {
        addToNoMaxPercentTotalSupply(newAddress);
        addToNoMaxPercentPerTx(newAddress);
        
        return true;
    }

        
    function noTax(address newAddress) public onlyOwner returns(bool) {
        addToNoMarketingTax(newAddress);
        addToNoDevTax(newAddress);
        addToNoBurnTax(newAddress);
        
        return true;
    } 
    
    
    
}