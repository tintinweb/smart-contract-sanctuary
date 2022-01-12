// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Ico is ERC20 {
    enum Stage {
        seed,
        general,
        open
    }

    enum Status {
        active,
        paused
    }

    address owner;
    address treasury;
    uint public amountRaised;
    Status public status;
    Stage public stage;
    uint constant SEED_INDIVIDUAL_LIMIT = 1500 ether;
    uint constant GENERAL_INDIVIDUAL_LIMIT = 1000 ether;
    uint constant SEED_MAX_CAP = 15000 ether;
    uint constant GENERAL_MAX_CAP = 30000 ether;
    uint constant CONVERSION = 5;
    bool public isTaxActive = true;
    mapping (address => uint) private _balances;
    mapping (address => uint) public contributions;
    mapping (address => bool) public whitelist;

    constructor(address _treasury) ERC20("Space Coin", "SPC") {
        owner = msg.sender;
        status = Status.active;
        stage = Stage.seed;
        treasury = _treasury;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Callable by owner only");
        _;
    }

    function contribute() public payable {
        require(status == Status.active, "ICO has been paused");
        if (stage == Stage.seed) {
            require(whitelist[msg.sender] == true, "Address not in whitelist");
            require(msg.value <= SEED_INDIVIDUAL_LIMIT, "Above contribution limit");
            require(amountRaised < SEED_MAX_CAP, "The seed stage is full");
        } else if (stage == Stage.general) {
            require(msg.value <= GENERAL_INDIVIDUAL_LIMIT, "Above contribution limit");
            require(amountRaised < GENERAL_MAX_CAP, "The general stage is full");
        } else if (stage == Stage.open) {
            require(amountRaised < GENERAL_MAX_CAP, "The open stage is full");
        }
        mintToUser();
    }

    function mintToUser() private {
        amountRaised += msg.value;
        contributions[msg.sender] += msg.value;
        _mint(msg.sender, (msg.value * 5) / 1000000000000000000);
    }

    function whiteList(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function collectFunds(uint amount) public payable onlyOwner{
        require(address(this).balance >= amount, "The requested amount is larger than the contract's balance");
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent == true, "Sending funds to the owner has failed");
    }

    function pause() public onlyOwner {
        status = Status.paused;
    }

    function resume() public onlyOwner {
        status = Status.active;
    }

    function moveStage() public onlyOwner {
        if (stage == Stage.seed) {
            stage = Stage.general;
        } else if (stage == Stage.general) {
            stage = Stage.open;
        }
    }

    function activateTax() public onlyOwner {
      isTaxActive = true;
    }

    function deactivateTax() public onlyOwner {
      isTaxActive = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        if (isTaxActive) {
          _balances[recipient] += amount * 49 / 50; // amount - 2% tax
          _balances[treasury] += amount * 1 / 50; // 2% tax
        } else {
          _balances[recipient] += amount;
        }

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
}