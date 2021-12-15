/**
 *Submitted for verification at snowtrace.io on 2021-12-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IAllocationController {
    function penguinTiers(address penguinAddress) external view returns(uint8);
    function allocations(address penguinAddress) external view returns(uint256);
    function totalAllocations() external view returns(uint256);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PenguinAllocationController is IAllocationController, Ownable {

    IERC20 immutable public IPEFI;
    IERC20 immutable public stakedIPEFI;
    uint256 public registrationStart;
    uint256 public registrationEnd;
    uint256 public penguinsAirdroppedTo;
    uint256 public totalAllocations;
    //min amount of allocations. anything below this is rounded to zero.
    uint256 public immutable MIN_ALLOC;
    uint256[] public allocationsTierHurdles;
    address[] public registeredPenguins;
    mapping(address => bool) public registered;
    mapping(address => uint256) public allocations;

    event AllocationsAssigned(address indexed penguinAddress, uint256 allocations);
    event Registered(address indexed penguinAddress);

    constructor(IERC20 _IPEFI, IERC20 _stakedIPEFI, uint256 _registrationStart, uint256 _registrationEnd, uint256 _MIN_ALLOC, uint256[] memory _allocationsTierHurdles) {
        require(_allocationsTierHurdles[0] == 0, "zeroth hurdle must be zero");
        require(_registrationEnd > _registrationStart, "registration period must have length > 0");
        require(address(_IPEFI) != address(0) && address(_stakedIPEFI) != address(0), "zero address bad");
        IPEFI = _IPEFI;
        stakedIPEFI = _stakedIPEFI;
        registrationStart = _registrationStart;
        registrationEnd = _registrationEnd;
        MIN_ALLOC = _MIN_ALLOC;
        allocationsTierHurdles = _allocationsTierHurdles;
    }

    function registrationPeriodOngoing() public view returns (bool) {
        return (block.timestamp >= registrationStart && block.timestamp <= registrationEnd);
    }

    //calculates expected allocations for an address based on its current balances
    function getAllocations(address penguinAddress) public view returns (uint256) {
        uint256 alloc = IPEFI.balanceOf(penguinAddress) + stakedIPEFI.balanceOf(penguinAddress);
        if (alloc >= MIN_ALLOC) {
            return alloc;
        } else {
            return 0;
        }
    }

    //finds the expected tier for an address based on its current balances
    function getTier(address penguinAddress) external view returns (uint8) {
        uint256 alloc = getAllocations(penguinAddress);
        for (uint8 i = uint8(allocationsTierHurdles.length - 1); i > 0; i--) {
            if (alloc >= allocationsTierHurdles[i]) {
                return i;
            }
        }
        return 0;
    }

    //finds the penguin tier of an address based on its real allocations
    function penguinTiers(address penguinAddress) external view returns (uint8) {
        uint256 alloc = allocations[penguinAddress];
        for (uint8 i = uint8(allocationsTierHurdles.length - 1); i > 0; i--) {
            if (alloc >= allocationsTierHurdles[i]) {
                return i;
            }
        }
        return 0;
    }

    //gets number of registered penguins
    function numberRegisteredPenguins() public view returns (uint256) {
        return registeredPenguins.length;
    }

    //
    function register() external {
        require(block.timestamp >= registrationStart, "registration has not yet started");
        require(block.timestamp <= registrationEnd, "registration has ended");
        require(!registered[msg.sender], "you've already registered");
        registered[msg.sender] = true;
        registeredPenguins.push(msg.sender);
        emit Registered(msg.sender);
    }

    //give allocations to users
    function airdropAllocations(uint256 numToAirdropTo) external onlyOwner {
        require(block.timestamp > registrationEnd, "registration period has not yet ended");
        uint256 penguinsLeft = numberRegisteredPenguins() - penguinsAirdroppedTo;
        if (numToAirdropTo > penguinsLeft) {
            numToAirdropTo = penguinsLeft;
        }
        for (uint256 i = 0; i < numToAirdropTo; i++) {
            address penguin = registeredPenguins[penguinsAirdroppedTo + i];
            uint256 allocationsToAssign = getAllocations(penguin);
            if (allocationsToAssign > 0) {
                allocations[penguin] = allocationsToAssign;
                totalAllocations += allocationsToAssign;
                emit AllocationsAssigned(penguin, allocationsToAssign);
            }
        }
        penguinsAirdroppedTo += numToAirdropTo;
    }

    function setRegistrationStart(uint256 _registrationStart) external onlyOwner {
        require(registrationEnd > _registrationStart, "registration period must have length > 0");
        registrationStart = _registrationStart;
    }

    function setRegistrationEnd(uint256 _registrationEnd) external onlyOwner {
        require(block.timestamp <= registrationEnd, "registration has ended");
        require(_registrationEnd > registrationStart, "registration period must have length > 0");
        registrationEnd = _registrationEnd;
    }

    function setAllocationTierHurdles(uint256[] calldata _allocationsTierHurdles) external onlyOwner {
        require(block.timestamp <= registrationEnd, "registration has ended");
        require(allocationsTierHurdles[0] == 0, "zeroth hurdle must be zero");
        allocationsTierHurdles = _allocationsTierHurdles;
    }
}