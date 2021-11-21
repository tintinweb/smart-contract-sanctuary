pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./BEP20.sol";

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract Mutocoin is BEP20, Ownable {
    using SafeMath for uint256;
    
    uint256 public _tokenPrice = 100000;
    
    address public teamAddress;
    
    mapping (address => bool) public minters;
    
    bool public canMint = false;
    bool public isSellStarted = false;
    
    constructor() BEP20("Mutocoin", "MUTO") {
        _mint(msg.sender, 100000000000000 *10**18);
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the Minter.
    function mint(address _to, uint256 _amount) public onlyMinter {
        require(!canMint, "No more minter");
        _mint(_to, _amount);
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }
    
    function stopMint() public onlyOwner {
        canMint = true;
    }
    
    function startSell() public onlyOwner {
        isSellStarted = true;
    }
    
    function stopSell() public onlyOwner {
        isSellStarted = false;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    
    function setTeamAddress(address _teamAdd) public onlyOwner {
        teamAddress = _teamAdd;
    }
    
    function buyToken() public payable {
        require(teamAddress != address(0), "Team address is zero address");
        require(isSellStarted, "Token sell not enabled..");
        uint256 value = msg.value;
        uint256 amountOfToken = _tokenPrice.mul(value);
        Token(address(this)).transferFrom(teamAddress, msg.sender, amountOfToken);
        transferBNB(payable(teamAddress), value);
    }
    
    function transferBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract
    function transferAnyBEP20Tokens(address tokenAdd, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "BEP20: amount must be greater than 0");
        require(recipient != address(0), "BEP20: recipient is the zero address");
        Token(tokenAdd).transfer(recipient, amount);
    }
    
    receive() external payable {
        buyToken();
    }
}