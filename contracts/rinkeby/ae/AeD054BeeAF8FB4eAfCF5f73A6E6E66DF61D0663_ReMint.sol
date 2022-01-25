/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Owner {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _pause;
    }

    function setPaused(bool p) external onlyOwner {
        _pause = p;
    }

    modifier checkContractCall() {
        require(contractCallable() || notContract(msg.sender), "non contract");
        _;
    }

    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }

    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able, _owner);
    }

    function notContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IWuFU721 {

    function mint(address recipient_, string memory tokenURI)
        external
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ITemplar {
    function myInventory(address owner, uint256 levelcode)
        external
        view
        returns (uint256[] memory available);
    
    function setTokenLevelCode(uint256 tokenId, uint256 levelCode) external;
}

contract ReMint is Owner {

    string tokenUrl = "https://ipfs.io/ipfs/QmS5pHGFtqa2tzS61bJZbjCwuugP6vCKt6frzsLm159fwq?filename=600-ChaoJiFu.json";
    address private DeadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256[5] levelType = [uint256(100),uint256(200),uint256(300),uint256(400),uint256(500)];

    IWuFU721 public immutable WuFu721;
    ITemplar public immutable Templar;


    constructor(address WuFu721_, address Templar_) {
        WuFu721 = IWuFU721(WuFu721_);
        Templar = ITemplar(Templar_);
    }

    function myInventoryExist(address owner, uint256 levelcode) private view returns (uint256) {
        uint256[] memory yAvailable = Templar.myInventory(owner, levelcode);
        uint256 amount = 0;
        for (uint256 i = 0; i < yAvailable.length; i++) {
            if (yAvailable[i] > 0) {
                amount++;
            }
        }
        return amount;
    }

    function isReMint(address owner) public view returns (uint256) {

        uint256 a = myInventoryExist(owner, levelType[0]);
        for (uint256 index = 1; index < 5; index++) {
            uint256 am = myInventoryExist(owner, levelType[index]);
            if (am < a) {
                a = am;
            }
        }

        return a;

    }


    function reMint() public checkContractCall checkPaused {
        uint256 amount = isReMint(msg.sender);
        
        for (uint256 i = 0; i < amount; i++) {
            
            uint256 tokenId = WuFu721.mint(msg.sender, tokenUrl);
            Templar.setTokenLevelCode(tokenId, 600);

            for (uint256 j = 0; j < 5 ; j++) {
                uint256 tokenid = Templar.myInventory(msg.sender, levelType[j])[0];
                WuFu721.transferFrom(msg.sender, DeadAddress, tokenid);
            }
        } 
    }
}