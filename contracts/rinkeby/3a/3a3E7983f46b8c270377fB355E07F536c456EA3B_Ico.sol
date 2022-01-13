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

    address public owner;
    address private treasury;
    uint public amountRaised;
    bool public isTaxActive;
    bool public isCancelled;
    Status public status;
    Stage public stage;
    address[] contributors;
    uint constant SEED_INDIVIDUAL_LIMIT = 1_500 ether;
    uint constant GENERAL_INDIVIDUAL_LIMIT = 1_000 ether;
    uint constant SEED_MAX_CAP = 15_000 ether;
    uint constant GENERAL_MAX_CAP = 30_000 ether;
    mapping (address => uint) public contributions;
    mapping (address => bool) public whitelist;

    constructor(address _treasury) ERC20("Space Coin", "SPC") {
        owner = msg.sender;
        status = Status.active;
        stage = Stage.seed;
        treasury = _treasury;
        isTaxActive = false;
        isCancelled = false;
        _mint(msg.sender, 500000 * 1e18);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Callable by owner only");
        _;
    }

    function contribute() external payable {
        require(status == Status.active, "ICO paused");
        if (stage == Stage.seed) {
            require(whitelist[msg.sender] == true, "Address not in whitelist");
            require(contributions[msg.sender] + msg.value <= SEED_INDIVIDUAL_LIMIT, "Above contribution limit");
            require(amountRaised < SEED_MAX_CAP, "The seed stage is full");
        } else if (stage == Stage.general) {
            require(contributions[msg.sender] + msg.value <= GENERAL_INDIVIDUAL_LIMIT, "Above contribution limit");
            require(amountRaised < GENERAL_MAX_CAP, "The general stage is full");
        } else if (stage == Stage.open) {
            require(amountRaised < GENERAL_MAX_CAP, "The open stage is full");
        }

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        amountRaised += msg.value;
        contributions[msg.sender] += msg.value;

        emit Contribute(msg.sender, msg.value);
    }

    function withdraw() external {
        require(isCancelled == true, "ICO needs to be cancelled");
        require(contributions[msg.sender] > 0, "You haven't contributed to this project");
        uint amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to withdraw Ether");

        emit Withdraw(msg.sender, amount);
    }

    function distributeTokens() private onlyOwner {
        for (uint i = 0 ; i < contributors.length; i++) {
            _transfer(msg.sender, contributors[i], contributions[contributors[i]] * 5);
        }
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(stage == Stage.open, "Tokens are still locked");
        if (isTaxActive) {
            _transfer(msg.sender, recipient, amount * 1e18 * 49 / 50);
            _transfer(msg.sender, treasury, amount * 1e18 * 1 / 50);
        } else {
            _transfer(msg.sender, recipient, amount * 1e18);
        }
    }

    function moveStage() external onlyOwner {
        if (stage == Stage.seed) {
            stage = Stage.general;
        } else if (stage == Stage.general) {
            stage = Stage.open;
            distributeTokens();
        }

        emit MoveStage();
    }

    function activateTax() external onlyOwner {
      isTaxActive = true;
    }

    function deactivateTax() external onlyOwner {
      isTaxActive = false;
    }

    function whitelistAddress(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function collectFunds(uint amount) external payable onlyOwner{
        require(address(this).balance >= amount, "The requested amount is larger than the contract's balance");
        require(isCancelled == false, "ICO cancelled");
        require(stage == Stage.open, "Can only collect in stage open");
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent == true, "Sending funds to the owner has failed");
    }

    function pause() external onlyOwner {
        status = Status.paused;
    }

    function resume() external onlyOwner {
        status = Status.active;
    }

    function cancelIco() external onlyOwner {
        require(stage != Stage.open, "Cannot cancel last stage");
        isCancelled = true;

        emit CancelIco();
    }

    event Contribute(address indexed contributor, uint amount);
    event Withdraw(address indexed to, uint amount);
    event CancelIco();
    event MoveStage();
}