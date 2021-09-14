// SPDX-License-Identifier: GPL v3
// bitmap is taken from uniswap/merkle-distributor

pragma solidity >= 0.6.0 <= 0.8.0;
import "SafeMath.sol";
import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "MerkleProof.sol";    

contract Airdrop {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Info {
        // 160+48+48 = 256
        address token_address;
        uint48 start_time;
        uint48 end_time;
    }

    address creator;
    bytes32 merkleRoot;
    Info info;
    mapping(uint256 => uint256) claimed_bitmap;             // #claimers/256 #claimers%25   source: Uniswap

    event Recharged(uint256 total, uint256 timestamp);
    event Claimed(uint256 amount, uint256 timestamp);
    event Withdrawed(uint256 left, uint256 timestamp);
    event RootChanged(bytes32 previous, bytes32 now);

    modifier creatorOnly {
        require(msg.sender == creator, "Not Authorized");
        _;
    }
    
    constructor (address _token_address, bytes32 _merkleRoot, uint256 _start_time, uint256 _end_time) {
        require(validRange(48, _start_time), "Invalid Start Time");
        require(validRange(48, _end_time), "Invalid End Time");

        merkleRoot = _merkleRoot;
        info.start_time = uint48(_start_time);
        info.end_time = uint48(_end_time);
        info.token_address = _token_address;
        creator = msg.sender;
    }

    function recharge (uint256 _total) public creatorOnly {
        Info memory _info = info;
        require(IERC20(_info.token_address).allowance(msg.sender, address(this)) >= _total, "WE NEED MORE!!!!!");
        IERC20(_info.token_address).safeTransferFrom(msg.sender, address(this), _total);
        emit Recharged(_total, block.timestamp);
    }

    function check(uint256 index, address claimer, uint256 amount, bytes32[] calldata merkleProof) external view
             returns (bool available, uint256 start, uint256 end, uint256 claimable) {
        require(!if_claimed(index), "Already Claimed");
        bytes32 leaf = keccak256(abi.encodePacked(index, claimer, amount));
        available = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        start = info.start_time;
        end = info.end_time;
        if (!available) {
            claimable = 0;
        } else {
            claimable = amount;
        }
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!if_claimed(index), "Already Claimed");
        require(block.timestamp > info.start_time, "Not Started");
        require(block.timestamp < info.end_time && (block.timestamp - info.start_time) / 86400 < 5, "Expired");
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'Not Verified');
        amount *= (10 ** 9);                                                               // 9 decimals
        IERC20(info.token_address).transfer(msg.sender, amount);
        set_claimed(index);
        emit Claimed(amount, block.timestamp); 
    }

    function if_claimed(uint256 index) internal view returns (bool) {
        return (claimed_bitmap[index/256] & (1 << (index%256))) == (1 << (index%256));
    }

    function set_claimed(uint256 index) internal {
        claimed_bitmap[index/256] = (1 << (index%256)) | (claimed_bitmap[index/256]);
    }

    function withdraw() public creatorOnly {
        Info memory _info = info;
        require(block.timestamp > _info.end_time, "Not Expired");
        uint256 left = IERC20(_info.token_address).balanceOf(address(this));
        require(left > 0, "What?");
        IERC20(_info.token_address).transfer(msg.sender, left);
        emit Withdrawed(left, block.timestamp);
    }

    function set_root(bytes32 root) external creatorOnly {
        emit RootChanged(merkleRoot, root);
        merkleRoot = root;
    }
    
    function validRange (uint16 size, uint256 data) internal pure returns (bool ifValid) {
        assembly {
            ifValid := or(eq(size, 256), gt(shl(size, 1), data))
        }
    }
}