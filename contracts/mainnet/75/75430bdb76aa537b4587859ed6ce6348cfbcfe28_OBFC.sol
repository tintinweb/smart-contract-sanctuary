// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "./IERC20.sol";

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

import "./SignatureCheck.sol";

contract OBFC is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(bytes12 => bool)) public authorizedSenders;
    mapping(address => bool) public authorizedAccounts;
    mapping(address => bool) public authorizedTokens;
    mapping(uint256 => bool) public authorizedRecipients;

    uint256 oneUnit = 10**18;
    uint256 public fee = 0;
    uint256 public min = 0;
    address public router;
    SignatureCheck public signatureCheck;

    event Transmit(
        address indexed transactor,
        bytes12 account,
        uint256 recipient,
        address token,
        uint256 amount,
        uint256 amountFee
    );

    event SetSenderAuthorization(
        address indexed transactor,
        bytes12 account,
        address indexed sender,
        bool isAuthorized
    );

    event ActivateAccount(
        address indexed transactor,
        bytes12 account,
        bytes signature
    );

    event AddRecipient(address indexed wallet, uint256 obfc, bytes signature);

    constructor(address _router, address _signerAddress) Ownable() {
        router = _router;
        signatureCheck = new SignatureCheck(_signerAddress);
    }

    function transmit(
        bytes12 _account,
        address _token,
        uint256 _amount,
        uint256 _recipientOBFC
    ) public returns (bool) {
        address from;
        require(_amount >= min);
        require(authorizedRecipients[_recipientOBFC] == true);
        if (authorizedSenders[msg.sender][_account] == true) {
            from = msg.sender;
        } else if (authorizedSenders[tx.origin][_account] == true) {
            from = tx.origin;
        }
        require(from != address(0));

        uint256 amountAfterFee = _amount.sub(fee);
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        token.transfer(router, amountAfterFee);
        emit Transmit(from, _account, _recipientOBFC, _token, _amount, fee);
        return true;
    }

    function setSenderAuthorization(
        bytes12 _account,
        address _sender,
        bool _isAuthorized
    ) public returns (bool) {
        require(authorizedSenders[msg.sender][_account] == true);
        authorizedSenders[_sender][_account] = _isAuthorized;
        emit SetSenderAuthorization(
            msg.sender,
            _account,
            _sender,
            _isAuthorized
        );
        return true;
    }

    function activateAccount(
        bytes12 _account,
        uint256 _signatureTimestamp,
        bytes memory _signature
    ) public returns (bool) {
        signatureCheck.activateAccount(
            msg.sender,
            _account,
            _signatureTimestamp,
            _signature
        );
        authorizedSenders[msg.sender][_account] = true;
        emit ActivateAccount(msg.sender, _account, _signature);
        return true;
    }

    function addRecipient(
        bytes12 _account,
        uint256 _recipientOBFC,
        uint256 _signatureTimestamp,
        bytes memory _signature
    ) public returns (bool) {
        signatureCheck.addRecipient(
            msg.sender,
            _account,
            _recipientOBFC,
            _signatureTimestamp,
            _signature
        );
        require(authorizedSenders[msg.sender][_account] == true);
        authorizedRecipients[_recipientOBFC] = true;
        emit AddRecipient(msg.sender, _recipientOBFC, _signature);
        return true;
    }

    function setSignerAddress(address _signerAddress)
        public
        onlyOwner
        returns (bool)
    {
        signatureCheck.setSignerAddress(_signerAddress);
        return true;
    }

    function setRouterAddress(address _router) public onlyOwner returns (bool) {
        router = _router;
        return true;
    }

    function setAuthorizedToken(address _token, bool _isAuthorized)
        public
        onlyOwner
        returns (bool)
    {
        authorizedTokens[_token] = _isAuthorized;
        return true;
    }

    function setFee(uint256 _fee) public onlyOwner returns (bool) {
        fee = _fee;
        return true;
    }

    function setMin(uint256 _min) public onlyOwner returns (bool) {
        fee = _min;
        return true;
    }

    function adminWithdraw(
        address _token,
        uint256 _amount,
        address _recipient
    ) public onlyOwner returns (bool) {
        IERC20 t = IERC20(_token);
        t.transfer(_recipient, _amount);
        return true;
    }
}