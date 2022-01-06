/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.7.6;


interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}


// store ETH in a contract for the contract owner to withdraw after time has expired for unlock date
contract ETHLockWallet {

    address public creator;
    address public owner;
    uint256 public unlockDate;
    uint256 public createdAt;
    string public message;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _creator, address _owner, uint256 _unlockDate, string memory _veryShortMessage) {
        require(_creator == tx.origin || _creator == msg.sender, "Creator must be caller");
        creator = _creator;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = block.timestamp;
        message = _veryShortMessage;
    }

    // keep all the ether sent to this address
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       require(block.timestamp >= unlockDate);
       //now send all the balance
       msg.sender.transfer(address(this).balance);
       emit Withdrew(msg.sender, address(this).balance);
    }


    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(block.timestamp >= unlockDate);
       ERC20 token = ERC20(_tokenContract);
       //now send all the token balance
       uint256 tokenBalance = token.balanceOf(address(this));
       token.transfer(owner, tokenBalance);
       emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function walletInfo() public view returns(address, address, uint256, uint256, uint256, string memory) {
        return (creator, owner, unlockDate, createdAt, address(this).balance, message);
    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}


contract ETHLockFactory {
    ETHLockWallet private wallet;
    mapping(address => address[]) private ethWalletsOwned;
    mapping(address => address[]) private ethWalletsCreated;

    function getETHWalletsOwned(address _address)public view returns(address[] memory) {
        return ethWalletsOwned[_address];
    }
    function getETHWalletsCreated(address _address)public view returns(address[] memory) {
        return ethWalletsCreated[_address];
    }

    function getETHWalletInfo(address payable _ethWallet) public view returns(address, address, uint256, uint256, uint256, string memory) {
        ETHLockWallet _wallet = ETHLockWallet(_ethWallet);
        return _wallet.walletInfo();
    }

    function createETHLockWallet(address _owner, uint256 _unlockDate, string memory _veryShortMessage) payable public returns(address){
        // Create new wallet.
        
        wallet = new ETHLockWallet(msg.sender, _owner, _unlockDate, _veryShortMessage);
        
        // Add wallet to sender's wallets and owner's wallets for tracking
        ethWalletsOwned[_owner].push(address(wallet));
        ethWalletsCreated[msg.sender].push(address(wallet));

        // Send ether from this transaction to the created contract.
        address(wallet).transfer(msg.value);

        // Emit event.
        emit Created(address(wallet), msg.sender, _owner, block.timestamp, _unlockDate, msg.value);
        return address(wallet);
    }

    // Prevents accidental sending of ether to the factory
    receive () external payable {
        revert();
    }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}