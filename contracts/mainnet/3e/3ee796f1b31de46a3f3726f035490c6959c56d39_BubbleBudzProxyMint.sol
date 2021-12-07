/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

abstract contract PayableGovernance is Ownable {
    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    // Payable Governance
    mapping(address => bool) internal shareholderToUnlockGovernance;

    address internal Shareholder_1 = 0x1D628369DD259660482bf6c14Cb558F8d69a8242; // Chief
    address internal Shareholder_2 = 0x1eD3D146cb5945e1C894A70013Ed83F95693EA22; // 0xInuarashi

    uint internal Shareholder_1_Share = 80; // Chief
    uint internal Shareholder_2_Share = 20; // 0xInuarashi

    function withdrawEther() public onlyOwner {
        uint _totalETH = address(this).balance; // balance of contract

        uint _Shareholder_1_ETH = ((_totalETH * Shareholder_1_Share) / 100); 
        uint _Shareholder_2_ETH = ((_totalETH * Shareholder_2_Share) / 100); 

        payable(Shareholder_1).transfer(_Shareholder_1_ETH);
        payable(Shareholder_2).transfer(_Shareholder_2_ETH);
    }
    function viewWithdrawEtherAmounts() public view onlyOwner returns (uint[] memory) {
        uint _totalETH = address(this).balance;
        uint[] memory _ethToSendArray = new uint[](4);

        uint _Shareholder_1_ETH = ((_totalETH * Shareholder_1_Share) / 100); 
        uint _Shareholder_2_ETH = ((_totalETH * Shareholder_2_Share) / 100); 

        _ethToSendArray[0] = _Shareholder_1_ETH;
        _ethToSendArray[1] = _Shareholder_2_ETH;
        _ethToSendArray[2] = _totalETH;
        _ethToSendArray[3] = _Shareholder_1_ETH + _Shareholder_2_ETH; 

        return _ethToSendArray;
    }

    // Payable Governance Emergency Functions
    modifier onlyShareholder {
        require(msg.sender == Shareholder_1 || msg.sender == Shareholder_2, "You are not a shareholder!");
        _;
    }
    modifier emergencyOnly {
        require(shareholderToUnlockGovernance[Shareholder_1] && shareholderToUnlockGovernance[Shareholder_2], "Emergency Functions have not been unlocked!");
        _;
    }

    function unlockEmergencyFunctionsAsShareholder() public onlyShareholder {
        shareholderToUnlockGovernance[msg.sender] = true;
    }
    function emergencyWithdrawEther() public onlyOwner emergencyOnly {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkGovernanceStatus(address address_) public view onlyShareholder returns (bool) {  
        return shareholderToUnlockGovernance[address_];
    }
}

interface iBubbleBudz {
    function ownerMintMany(address to_, uint256 amount_) external;
    function transferOwnership(address newOwner_) external;
    function ownerOf(uint256 tokenId_) external view returns (address);
    function normalTokensLimit() external view returns (uint256);
    function normalTokensMinted() external view returns (uint256);
    function addressToWhitelistMints(address address_) external view returns (uint256);
    function addressToPublicMints(address address_) external view returns (uint256);
    function withdrawEther() external;
}

contract BubbleBudzProxyMint is Ownable, PayableGovernance {
    // General NFT Variables
    uint256 public mintPrice = 0.045 ether;
    uint256 public maxMintsPerTx = 50;

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_; }
    function setMaxMintsPerTx(uint256 maxMintsPerTx_) external onlyOwner {
        maxMintsPerTx = maxMintsPerTx_; }

    // Access
    function transferOwnershipOfBubbleBudz(address newOwner_) external onlyOwner {
        BB.transferOwnership(newOwner_);
    }

    // Interfaces
    iBubbleBudz public BB;
    function setBubbleBudz(address address_) external onlyOwner {
        BB = iBubbleBudz(address_); }

    // Modifiers
    modifier onlySender{ require(msg.sender == tx.origin, "No contracts"); _; }

    // Owner Mint Logic
    function ownerMint(address to_, uint256 amount_) public onlyOwner {
        BB.ownerMintMany(to_, amount_); }

    // Minting Proxy Logic
    bool public publicMintEnabled = true;
    modifier publicMint { require(publicMintEnabled, "Public Mint is not Enabled!"); _; }
    function setPublicMint(bool bool_) external onlyOwner { publicMintEnabled = bool_; }

    function mint(uint256 amount_) public payable onlySender publicMint {
        // Checks that mints is remaining, within tx, and has the correct value sent.
        require(BB.normalTokensLimit() >= BB.normalTokensMinted() + amount_, "No more mints remaining!");
        require(maxMintsPerTx >= amount_, "Over maximum mints per tx!");
        require(msg.value == mintPrice * amount_, "Invalid value sent!");
        
        // Mint many to the msg.sender.
        BB.ownerMintMany(msg.sender, amount_); // This calls the main contract to mint
    }

    // Claiming Proxy Logic
    mapping(address => uint256) public addressToBBClaimed;

    bool public publicClaimEnabled = true;
    modifier publicClaim { require(publicClaimEnabled, "Public Claiming is not Enabled!"); _; }
    function setPublicClaim(bool bool_) external onlyOwner { publicClaimEnabled = bool_; }

    function claim() public onlySender publicClaim {
        // Querys the amount to claim based on two mappings. Then, checks if claimed already or not. 
        // Lastly, check if token supply is enough.
        uint256 _claimable = BB.addressToPublicMints(msg.sender) + BB.addressToWhitelistMints(msg.sender);
        require(addressToBBClaimed[msg.sender] == 0, "You have already claimed your Bubble Budz!");
        require(BB.normalTokensLimit() >= BB.normalTokensMinted() + _claimable, "No more supply remaining!");

        // Set the address as claimed with the _claimable amount.
        addressToBBClaimed[msg.sender] += _claimable; // add the claimed amount

        // Mint many to the msg.sender.
        BB.ownerMintMany(msg.sender, _claimable);
    }

    // Just In Case
    function BBWithdrawEther() external onlyOwner {
        BB.withdrawEther();
    }
}