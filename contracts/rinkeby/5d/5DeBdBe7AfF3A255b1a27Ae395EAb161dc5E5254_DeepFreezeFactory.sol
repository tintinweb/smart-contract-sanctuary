//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// DeepFreeze V0

contract DeepFreezeFactory {
    address public creatorOwner; // public state variable automatically has getter function
    DeepFreeze[] public deployedFreezer; // public array automatically has getter function
    mapping(address => DeepFreeze[]) public userFreezer; // address maps to array of freezers
    event FreezerDeployed(address from, address freezerAddress);

    constructor() {
        creatorOwner = msg.sender;
    }

    function createDeepFreeze(string memory hint_, bytes32 password_) public {
        DeepFreeze new_freezer_address = new DeepFreeze(
            msg.sender,
            hint_,
            password_
        );
        userFreezer[msg.sender].push(new_freezer_address); // track freezers at the owner level
        // NOTE self-destructed freezers are not popped as they may not be the last freezer in array.
        // simply ignore them in UI
        deployedFreezer.push(new_freezer_address);
        emit FreezerDeployed(msg.sender, address(new_freezer_address));
    }
}

contract DeepFreeze {
    address payable public FreezerOwner; // publicly visible owner of the freezer
    string internal _hint;
    bytes32 internal _password;
    event FundDeposited(address indexed freezer, uint256 amount);
    event FundWithdrawed(address indexed freezer, address _to, uint256 amount);

    constructor(
        address eoa,
        string memory hint_,
        bytes32 password_
    ) {
        FreezerOwner = payable(eoa);
        _hint = hint_;
        _password = password_;
    }

    modifier onlyOwner() {
        require(
            msg.sender == FreezerOwner,
            "Only the freezer owner can do that!"
        );
        _;
    }

    function requestHint() public view onlyOwner returns (string memory) {
        return _hint;
    }

    function requestKey() public view onlyOwner returns (bytes32) {
        return _password;
    }

    function deposit() public payable {
        emit FundDeposited(address(this), msg.value);
        // accept deposits from anyone - ONLY THE BLOCKCHAIN's NATIVE ASSET! NOT ERC-20
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(string memory password_) public onlyOwner {
        require(
            keccak256(abi.encodePacked(password_)) == _password,
            "Your passphrase is wrong."
        );
        require(getBalance() != 0, "There's nothing to withdraw.");
        uint256 balance = address(this).balance;
        address freezerAddress = address(this);
        // Input code for withdrawing a specific ERC-20 asset.
        selfdestruct(FreezerOwner); // automatically sends **ETH** to owner address upon contract death.
        // ONLY ETH. Don't self destruct with ERC-20 balance!
        emit FundWithdrawed(freezerAddress, FreezerOwner, balance);
    }
}