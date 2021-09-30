/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

pragma solidity ^0.8.8;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}


contract SignedPayer {
    address private constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable SIGNER;
    address payable private immutable GOVERNOR;
    mapping(bytes32 => bool) public _executed;

    event Paid(IERC20 indexed token, address indexed recipient, uint256 amount);


    modifier onlyGovernor() {
        require(GOVERNOR == msg.sender, "Ownable: caller is not the Governor");
        _;
    }

    constructor(address signer, address payable governor) {
        require(signer != address(0), 'INVALID_SIGNER');
        require(governor != address(0), 'INVALID_GOVERNOR');
        SIGNER = signer;
        GOVERNOR = governor;
    }

    function pay(
        address payable recipient,
        IERC20 token,
        uint256 amount,
        uint256 nonce,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        public
    {
        bytes32 hash = getPaymentHash(recipient, token, amount, nonce);
        require(!_executed[hash], 'ALREADY_EXECUTED');
        _executed[hash] = true;
        require(_getSigner(hash, r, s, v) == SIGNER, 'INVALID_SIGNATURE');
        _transferToken(token, recipient, amount);
        emit Paid(token, recipient, amount);
    }

    function batchPay(
        address payable[] memory recipients,
        IERC20[] memory token,
        uint256[] calldata amounts,
        uint256[] calldata nonces,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint8[] memory v
    )
        external
    {
        uint256 size = recipients.length;
        require(token.length == size, 'TOKEN[] size mismatch');
        require(amounts.length == size, 'AMOUNTS[] size mismatch');
        require(nonces.length == size, 'NONCES[] size mismatch');
        require(r.length == size, 'R[] size mismatch');
        require(s.length == size, 'S[] size mismatch');
        require(v.length == size, 'V[] size mismatch');
        for (uint256 i = 0; i < recipients.length; i++){
            pay(recipients[i], token[i], amounts[i], nonces[i], r[i], s[i], v[i]);
        }

    }
    function getPaymentHash(address recipient, IERC20 token, uint256 amount, uint256 nonce)
        public
        view
        returns (bytes32 hash)
    {
        return keccak256(abi.encode(address(this), recipient, token, amount, nonce));
    }

    function _getSigner(bytes32 hash, bytes32 r, bytes32 s, uint8 v)
        private
        pure
        returns (address signer)
    {
        return ecrecover(hash, v, r, s);
    }

    function _transferToken(IERC20 token, address payable recipient, uint256 amount)
        private
    {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            (bool success, bytes memory result) = recipient.call{value: amount}("");
            if (!success) {
                revert(string(result));
            }
            return;
        }
        (bool success, bytes memory result) = address(token).call(
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                recipient,
                amount
            )
        );
        if (!success) {
            revert(string(result));
        }

        if (result.length >= 32) {
            require(abi.decode(result, (bool)), 'ERC20_TRANSFER_FAILED');
        }
    }

    function adminExit(IERC20 token, address payable recipient) external onlyGovernor{
        _transferToken(token, recipient, token.balanceOf(address(this)));
    }

    receive() external payable {

    }
}