/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/MerkleAirdrop.sol

// Modified from https://github.com/Phala-Network/prelaunch-token/blob/master/contracts/MerkleAirdrop.sol

pragma solidity 0.5.17;


contract MerkleAirdrop {
    struct Airdrop {
        bytes32 root;
        string dataURI;
        bool paused;
        mapping(address => bool) awarded;
    }

    // Events
    event Start(uint256 id);
    event PauseChange(uint256 id, bool paused);
    event Award(uint256 id, address recipient, uint256 amount);

    // States
    mapping(uint256 => Airdrop) public airdrops;
    IERC20 public token;
    uint256 public airdropsCount;

    address public core;

    // Errors
    string private constant ERROR_AWARDED = "AWARDED";
    string private constant ERROR_INVALID = "INVALID";
    string private constant ERROR_PAUSED = "PAUSED";
    string private constant ERROR_INVALID_BAL = "INVALID_BAL";

    modifier onlyCore() {
        require(msg.sender == core, "Not Authorized");
        _;
    }

    constructor() public {
        core = msg.sender;
    }

    function setToken(address _token) public onlyCore {
        token = IERC20(_token);
    }

    /**
     * @notice Start a new airdrop `_root` / `_dataURI`
     * @param _root New airdrop merkle root
     * @param _dataURI Data URI for airdrop data
     */
    function start(bytes32 _root, string memory _dataURI) public onlyCore {
        require(token.balanceOf(address(this)) > 0, ERROR_INVALID_BAL);

        uint256 id = ++airdropsCount; // start at 1
        airdrops[id] = Airdrop(_root, _dataURI, false);
        emit Start(id);
    }

    /**
     * @notice Pause or resume an airdrop `_id` / `_paused`
     * @param _id The airdrop to change status
     * @param _paused Pause to resume
     */
    function setPause(uint256 _id, bool _paused) public onlyCore {
        require(_id <= airdropsCount, ERROR_INVALID);
        airdrops[_id].paused = _paused;
        emit PauseChange(_id, _paused);
    }

    /**
     * @notice Remove tokens after airdrop has finished.
     */
    function removeToken() public onlyCore {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(core, balance);
        }
    }

    /**
     * @notice Fetch Award from airdrop
     * @param _id Airdrop id
     * @param _recipient Airdrop recipient
     * @param _amount The token amount
     * @param _proof Merkle proof to correspond to data supplied
     */
    function award(
        uint256 _id,
        address _recipient,
        uint256 _amount,
        bytes32[] memory _proof
    ) public {
        require(_id <= airdropsCount, ERROR_INVALID);

        Airdrop storage airdrop = airdrops[_id];
        require(!airdrop.paused, ERROR_PAUSED);

        bytes32 hash = keccak256(abi.encodePacked(_recipient, _amount));
        require(validate(airdrop.root, _proof, hash), ERROR_INVALID);

        require(!airdrops[_id].awarded[_recipient], ERROR_AWARDED);

        airdrops[_id].awarded[_recipient] = true;

        uint256 bal = token.balanceOf(address(this));
        if (bal >= _amount) {
            token.transfer(_recipient, _amount);
        } else {
            revert("INVALID_CONTRACT_BALANCE");
        }

        emit Award(_id, _recipient, _amount);
    }

    /**
     * @notice Fetch Award from many airdrops
     * @param _ids Airdrop ids
     * @param _recipient Recepient of award
     * @param _amounts The amounts
     * @param _proofs Merkle proofs
     * @param _proofLengths Merkle proof lengths
     */
    function awardFromMany(
        uint256[] memory _ids,
        address _recipient,
        uint256[] memory _amounts,
        bytes memory _proofs,
        uint256[] memory _proofLengths
    ) public {
        uint256 totalAmount;

        uint256 marker = 32;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(id <= airdropsCount, ERROR_INVALID);
            require(!airdrops[id].paused, ERROR_PAUSED);

            bytes32[] memory proof =
                extractProof(_proofs, marker, _proofLengths[i]);
            marker += _proofLengths[i] * 32;

            bytes32 hash = keccak256(abi.encodePacked(_recipient, _amounts[i]));
            require(validate(airdrops[id].root, proof, hash), ERROR_INVALID);

            require(!airdrops[id].awarded[_recipient], ERROR_AWARDED);

            airdrops[id].awarded[_recipient] = true;

            totalAmount += _amounts[i];

            emit Award(id, _recipient, _amounts[i]);
        }

        uint256 bal = token.balanceOf(address(this));
        if (bal >= totalAmount) {
            token.transfer(_recipient, totalAmount);
        } else {
            revert("INVALID_CONTRACT_BALANCE");
        }
    }

    function extractProof(
        bytes memory _proofs,
        uint256 _marker,
        uint256 proofLength
    ) public pure returns (bytes32[] memory proof) {
        proof = new bytes32[](proofLength);

        bytes32 el;

        for (uint256 j = 0; j < proofLength; j++) {
            assembly {
                el := mload(add(_proofs, _marker))
            }
            proof[j] = el;
            _marker += 32;
        }
    }

    function validate(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 hash
    ) public pure returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            if (hash < proof[i]) {
                hash = keccak256(abi.encodePacked(hash, proof[i]));
            } else {
                hash = keccak256(abi.encodePacked(proof[i], hash));
            }
        }

        return hash == root;
    }

    /**
     * @notice Check if recipient:`_recipient` awarded from airdrop:`_id`
     * @param _id Airdrop id
     * @param _recipient Recipient to check
     */
    function awarded(uint256 _id, address _recipient)
        public
        view
        returns (bool)
    {
        return airdrops[_id].awarded[_recipient];
    }
}