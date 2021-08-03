//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IHotwalletRepository {
    function hotwallet() external view returns (address);
}

interface ISignersRepository {
    function isSigner(address _signer) external view returns (bool);
}

contract Token is ERC20Pausable, Ownable {
    using SafeMath for uint256;


    uint256 public taxRate;
    address public taxReceiver;
    uint256 immutable private _cap;

    mapping(uint256 => bool) public withdrawIDs;
    mapping(uint256 => bool) public mintIDs;
    mapping(address => bool) public taxWhitelist;

    IHotwalletRepository hotwalletRepository;
    ISignersRepository signersRepository;

    event Deposited(string indexed tokendID, uint256 amount);
    event Withdrawn(uint256 indexed reqID);
    event TaxReceiverSet(address indexed taxReceiver);
    event AddedToWhitelist(address indexed whitelistAddress);
    event RemovedFromWhitelist(address indexed whitelistAddress);

    uint256 constant WITHDRAW_OP = 1;
    uint256 constant MINT_OP = 2;
    uint256 public constant TAX_RATE_DIVISOR = 10000;
    uint256 public constant MAX_TAX_RATE = 1000; // 10%

    modifier isSigned(
        uint256 _prefix,
        uint256 _amount,
        uint256 _requestID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) {
        bytes32 _hash = keccak256(abi.encodePacked(_prefix, msg.sender, _requestID, _amount));
        {
            address signer = ecrecover(_hash, _v, _r, _s);
            require(signer != address(0), "bad-signature");
            require(signersRepository.isSigner(signer), "bad-signer");
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _hotwalletRepository,
        address _signers,
        uint256 cap_,
        uint256 taxRate_,
        address taxReceiver_
    ) ERC20(_name, _symbol)  Ownable() {
        signersRepository = ISignersRepository(_signers);
        hotwalletRepository = IHotwalletRepository(_hotwalletRepository);
        taxWhitelist[msg.sender] = true;
        taxWhitelist[taxReceiver_] = true;
        taxRate = taxRate_;
        taxReceiver = taxReceiver_;
        _cap = cap_;
    }

    function setTaxReceiver(address taxReceiver_) external onlyOwner {
        taxReceiver = taxReceiver_;
        emit TaxReceiverSet(taxReceiver_);
    }

    function addToWhitelist(address whitelistAddress) external onlyOwner {
        taxWhitelist[whitelistAddress] = true;
        emit AddedToWhitelist(whitelistAddress);
    }

    function removeFromWhitelist(address whitelistAddress) external onlyOwner {
        taxWhitelist[whitelistAddress] = false;
        emit RemovedFromWhitelist(whitelistAddress);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        uint256 sendAmount = amount;
        if (!taxWhitelist[sender]) {
            uint256 taxAmount = amount.mul(taxRate).div(TAX_RATE_DIVISOR);
            _balances[taxReceiver] = _balances[taxReceiver].add(taxAmount);
            emit Transfer(sender, taxReceiver, taxAmount);
            sendAmount = sendAmount.sub(taxAmount);
        }
        _balances[recipient] = _balances[recipient].add(sendAmount);
        emit Transfer(sender, recipient, sendAmount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function mintBySignature(
        uint256 amount,
        uint256 requestID,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external isSigned(MINT_OP, amount, requestID, r, s, v) {
        require(!mintIDs[requestID], "mint-id-used");
        require(!paused(), "token-is-paused");
        _mint(hotwalletRepository.hotwallet(), amount);
        mintIDs[requestID] = true;
    }

    function mint(
        uint256 amount,
        address account
    ) external onlyOwner() {
        require(!paused(), "token-is-paused");
        _mint(account, amount);
    }

    function deposit(
        string memory _tokendID,
        uint256 _amount
    ) external returns (bool){
        require(!paused(), "token-is-paused");

        _transfer(msg.sender, hotwalletRepository.hotwallet(), _amount);
        emit Deposited(_tokendID, _amount);

        return true;
    }

    function withdraw(
        uint256 _amount,
        uint256 _requestID,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) isSigned(WITHDRAW_OP, _requestID, _amount, _r, _s, _v) external returns (bool){
        require(!paused(), "token-is-paused");
        require(!withdrawIDs[_requestID], "withdraw-id-used");
        require(balanceOf(msg.sender) >= _amount, "balance-too-low");
        withdrawIDs[_requestID] = true;
        _transfer(hotwalletRepository.hotwallet(), msg.sender, _amount);
        emit Withdrawn(_requestID);
        return true;
    }
}