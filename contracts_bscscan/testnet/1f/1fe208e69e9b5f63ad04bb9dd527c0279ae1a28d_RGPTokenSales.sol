/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function distributeTokens(address to, uint tokens, uint256 lockingPeriod) external returns (bool);
}

// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!
pragma solidity 0.8.7;

// File: @openzeppelin/contracts/GSN/Context.sol

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";

contract RGPTokenSales {
    
    bool    public saleActive;
    address public busd;
    address public rgp;
    address public owner;
    uint    public price;
    
    mapping(address => bool) public isWhitelist;
    mapping(address => bool) public isAdminAddress;
    mapping(address => uint256) public userFunds;
    address[] public users;
    
    uint256 public lockedFunds;
    
    
    // Emitted when tokens are sold
    event Sale(address indexed account, uint indexed price, uint tokensGot);
    event distruted(address indexed sender, address indexed recipient, uint256 rewards);
    
    // emmitted when an address is whitelisted.....
    event Whitelist(
        address indexed userAddress,
        bool Status
    );
    
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"RGP TOKEN: YOU ARE NOT THE OWNER.");
        _;
    }
    
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()]);
        _;
    }

    constructor( address _busd, address _rgp, uint256 _price) {
        owner =  _msgSender();
        isWhitelist[_msgSender()] = true;
        isAdminAddress[_msgSender()] = true;
        saleActive = true;
        busd = _busd;
        rgp = _rgp;
        saleActive = true;
        price = _price;
    }
    
    
    // Change the token price
    // Note: Set the price respectively considering the decimals of busd
    // Example: If the intended price is 0.01 per token, call this function with the result of 0.01 * 10**18 (_price = intended price * 10**18; calc this in a calculator).
    function tokenPrice(uint _price) external onlyOwner {
        price = _price;
    }
    
   
    // Buy tokens function
    // Note: This function allows only purchases of "full" tokens, purchases of 0.1 tokens or 1.1 tokens for example are not possible
    function lockFund(uint256 _tokenAmount) public {
        
        require(isWhitelist[_msgSender()], "RGP: Address Not whitelisted");
        
        // Check if sale is active and user tries to buy atleast 1 token
        require(saleActive == true, "RGP: SALE HAS ENDED.");
        require(_tokenAmount >= 1, "RGP: BUY ATLEAST 1 TOKEN.");
        
        // Transfer busd from _msgSender() to the contract
        // If it returns false/didn't work, the
        //  msg.sender may not have allowed the contract to spend busd or
        //  msg.sender or the contract may be frozen or
        //  msg.sender may not have enough busd to cover the transfer.
        require(IERC20(busd).transferFrom(_msgSender(), address(this), _tokenAmount), "RGP: TRANSFER OF BUSD FAILED!");
        
        // update user data on the contract..
        userFunds[_msgSender()] += _tokenAmount;
        
        // store user
        users.push(_msgSender());
        
        lockedFunds = lockedFunds + _tokenAmount;
        emit Sale(_msgSender(), price, _tokenAmount);
    }
    
    // distribute users rewards
    // can only be called by the owner
    // it delete all the users store in the contract
    function distribute() public onlyOwner {
        uint256 userLength = users.length; // for gas efficiency
        for(uint256 i = 0; i < userLength; i++) {
            address wallet = users[i];
            uint256 _locked = userFunds[wallet];
            (uint256 amount) = getUser(wallet);
            userFunds[wallet] - _locked;
            lockedFunds - _locked;
            IERC20(rgp).transferFrom(owner, wallet, amount);
            emit distruted(owner, wallet, amount);
        }
        delete(users);
    }
    
    function getUser(address _user) public view returns(uint256 rewards) {
        rewards = userFunds[_user] * price;
        return ( rewards / 1E18);
    }
    
    function userLenghtArg() public view returns(uint256) {
        return users.length;
    }
    
    // End the sale, don't allow any purchases anymore and send remaining rgp to the owner
    function disableSale() external onlyOwner{
        
        // End the sale
        saleActive = false;
        
        // Send unsold tokens and remaining busd to the owner. Only ends the sale when both calls are successful
        IERC20(rgp).transfer(owner, IERC20(rgp).balanceOf(address(this)));
    }
    
    // Start the sale again - can be called anytime again
    // To enable the sale, send RGP tokens to this contract
    function enableSale() external onlyOwner{
        
        // Enable the sale
        saleActive = true;
        
        // Check if the contract has any tokens to sell or cancel the enable
        require(IERC20(rgp).balanceOf(address(this)) >= 1, "RGP: CONTRACT DOES NOT HAVE TOKENS TO SELL.");
    }
    
    // Withdraw busd to _recipient
    function withdrawBUSD() external onlyOwner {
        uint _busdBalance = IERC20(busd).balanceOf(address(this));
        require(_busdBalance >= 1, "RGP: NO BUSD TO WITHDRAW");
        IERC20(busd).transfer(owner, _busdBalance);
    }
    
    // Withdraw (accidentally) to the contract sent eth
    function withdrawETH() external payable onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }
    
    // Withdraw (accidentally) to the contract sent ERC20 tokens except rgp
    function withdrawIERC20(address _token) external onlyOwner {
        uint _tokenBalance = IERC20(_token).balanceOf(address(this));
        
        // Don't allow RGP to be withdrawn (use endSale() instead)
        require(_tokenBalance > 0 && _token != rgp, "RGP: CONTRACT DOES NOT OWN THAT TOKEN OR TOKEN IS RGP.");
        IERC20(_token).transfer(owner, _tokenBalance);
    }
    
    // use to add multiple address to perform an admin operation on the contract....
    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isAdminAddress[_adminAddress[i]] = status;
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
                delete(isAdminAddress[_adminAddress[i]]);
            }
        }
    }
    
    // use to whitelist multiple address to perform transaction on the contract....
    function updateWhitelist(address[] calldata _adminAddress, bool status) external onlyAdmin {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isWhitelist[_adminAddress[i]] = status;
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
               delete(isWhitelist[_adminAddress[i]]);
            } 
        }
    
    }
    
}