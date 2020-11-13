// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";

import "./interfaces/IERC721Token.sol";
import "./interfaces/IERC721Receiver.sol";

import "./LavaToken.sol";

import "./libs/Strings.sol";
import "./libs/Godable.sol";

import "@nomiclabs/buidler/console.sol";

// In the fertile sacred grove under the lightning tree ThunderEggs are spawned!
//
// ThunderEggs are controlled by a god that wields tremendous power. You have been warned!
//
// Don't mess with the Gods especially the God of Thunder!
//
contract ThunderEgg is Godable, IERC721Token, ERC165 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ** Chef

    // Info of each ThunderEgg.
    struct ThunderEggInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of lava entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accLavaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accLavaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each sacred grove.
    struct SacredGrove {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. lavas to distribute per block.
        uint256 lastRewardBlock;  // Last block number that lavas distribution occurs.
        uint256 accLavaPerShare; // Accumulated lava per share, times 1e18. See below.
        uint256 totalSupply; // max ThunderEggs for this pool
        uint256 endBlock; // god has spoken - this pool is 'ova
    }

    // The lavaToken TOKEN!
    LavaToken public lava;

    // Block number when bonus period ends.
    uint256 public bonusEndBlock;

    // Lava tokens created per block.
    uint256 public lavaPerBlock;

    // Bonus muliplier for early makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Offering to the GODS
    uint256 public godsOffering = 80; // 1.25%

    // Info of each grove.
    SacredGrove[] public sacredGrove;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(uint256 => ThunderEggInfo)) public thunderEggInfoMapping;

    // Total allocation poitns. Must be the sum of all allocation points in all groves.
    uint256 public totalAllocPoint = 0;

    // The block number when mining starts.
    uint256 public startBlock;

    mapping(address => bool) public isSacredGrove;

    event Deposit(address indexed user, uint256 indexed groveId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed groveId, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed groveId, uint256 amount);

    // ** end Chef

    // ** ERC721

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // Function selector for ERC721Receiver.onERC721Received
    // 0x150b7a02
    bytes4 constant internal ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    string public baseTokenURI;

    // Note: the first token ID will be 1
    uint256 public tokenPointer;

    // Token name
    string public name = "ThunderEgg";

    // Token symbol
    string public symbol = "TEGG";

    // total supply across sacred groves
    uint256 public totalSupply;
    uint256 public totalSpawned;
    uint256 public totalDestroyed;

    // Mapping of eggId => owner
    mapping(uint256 => address) internal thunderEggIdToOwner;
    mapping(uint256 => uint256) internal thunderEggIdToBirth;
    mapping(uint256 => bytes32) internal thunderEggIdToName;

    mapping(address => uint256) public ownerToThunderEggId;

    // Mapping of eggId => approved address
    mapping(uint256 => address) internal approvals;

    // Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    // ** end ERC721

    constructor(
        LavaToken _lava,
        uint256 _lavaPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        lava = _lava;
        lavaPerBlock = _lavaPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function sacredGroveLength() external view returns (uint256) {
        return sacredGrove.length;
    }

    // Add a new sacred grove. Can only be called by god!!
    function addSacredGrove(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyGod {
        require(!isSacredGrove[address(_lpToken)], "This is already a known sacred grove");

        if (_withUpdate) {
            massUpdateSacredGroves();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        sacredGrove.push(SacredGrove({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accLavaPerShare : 0,
            totalSupply : 0,
            endBlock : 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            }));

        isSacredGrove[address(_lpToken)] = true;
    }

    // Update the given grove's allocation point. Can only be called by the owner.
    function set(uint256 _groveId, uint256 _allocPoint, bool _withUpdate) public onlyGod {
        if (_withUpdate) {
            massUpdateSacredGroves();
        }
        totalAllocPoint = totalAllocPoint.sub(sacredGrove[_groveId].allocPoint).add(_allocPoint);
        sacredGrove[_groveId].allocPoint = _allocPoint;
    }

    function end(uint256 _groveId, uint256 _endBlock, bool _withUpdate) public onlyGod {
        SacredGrove storage grove = sacredGrove[_groveId];
        grove.endBlock = _endBlock;

        if (_withUpdate) {
            massUpdateSacredGroves();
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
        }
    }

    function thunderEggStats(uint256 _groveId, uint256 _eggId) external view returns (address _owner, uint256 _birth, uint256 _age, uint256 _lp, uint256 _lava, bytes32 _name) {
        if (!_exists(_eggId)) {
            return (address(0x0), 0, 0, 0, 0, bytes32(0x0));
        }

        ThunderEggInfo storage info = thunderEggInfoMapping[_groveId][_eggId];

        return (
        thunderEggIdToOwner[_eggId],
        thunderEggIdToBirth[_eggId],
        block.number - thunderEggIdToBirth[_eggId],
        info.amount,
        _calculatePendingLava(_groveId, _eggId),
        thunderEggIdToName[_eggId]
        );
    }

    // View function to see pending LAVAs on frontend.
    function pendingLava(uint256 _groveId, uint256 _eggId) external view returns (uint256) {
        // no ThunderEgg, no lava!
        if (!_exists(_eggId)) {
            return 0;
        }

        return _calculatePendingLava(_groveId, _eggId);
    }

    function _calculatePendingLava(uint256 _groveId, uint256 _eggId) internal view returns (uint256) {
        SacredGrove storage grove = sacredGrove[_groveId];
        ThunderEggInfo storage info = thunderEggInfoMapping[_groveId][_eggId];

        uint256 accLavaPerShare = grove.accLavaPerShare;

        uint256 lpSupply = grove.lpToken.balanceOf(address(this));
        if (block.number > grove.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(grove.lastRewardBlock, block.number <= grove.endBlock ? block.number : grove.endBlock);
            uint256 lavaReward = multiplier.mul(lavaPerBlock).mul(grove.allocPoint).div(totalAllocPoint);
            accLavaPerShare = accLavaPerShare.add(lavaReward.mul(1e18).div(lpSupply));
        }

        return info.amount.mul(accLavaPerShare).div(1e18).sub(info.rewardDebt);
    }

    // Update reward variables for all grove. Be careful of gas spending!
    function massUpdateSacredGroves() public {
        uint256 length = sacredGrove.length;
        for (uint256 groveId = 0; groveId < length; ++groveId) {
            updateSacredGrove(groveId);
        }
    }

    // Update reward variables of the given grove to be up-to-date.
    function updateSacredGrove(uint256 _groveId) public {
        SacredGrove storage grove = sacredGrove[_groveId];
        if (block.number <= grove.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = grove.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            grove.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(grove.lastRewardBlock, block.number <= grove.endBlock ? block.number : grove.endBlock);
        uint256 lavaReward = multiplier.mul(lavaPerBlock).mul(grove.allocPoint).div(totalAllocPoint);

        // offering to the gods
        lava.mint(god(), lavaReward.div(godsOffering));

        // reward for ThunderEggs
        lava.mint(address(this), lavaReward);

        grove.accLavaPerShare = grove.accLavaPerShare.add(lavaReward.mul(1e18).div(lpSupply));
        grove.lastRewardBlock = block.number;
    }

    // mint the ThunderEgg by depositing LP tokens,
    function spawn(uint256 _groveId, uint256 _amount, bytes32 _name) public {
        require(ownerToThunderEggId[msg.sender] == 0, "Thor has already blessed you with a ThunderEgg!");
        require(_amount > 0, "You must sacrifice your LP tokens to the gods!");

        updateSacredGrove(_groveId);

        // Thunder 🥚 time!
        uint256 eggId = _mint(_groveId, msg.sender, _name);

        SacredGrove storage pool = sacredGrove[_groveId];
        ThunderEggInfo storage info = thunderEggInfoMapping[_groveId][eggId];

        // credit the staked amount
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        info.amount = info.amount.add(_amount);

        info.rewardDebt = info.amount.mul(pool.accLavaPerShare).div(1e18);
        emit Deposit(msg.sender, _groveId, _amount);
    }

    // Destroy and get all the tokens back - bye bye NFT!
    function destroy(uint256 _groveId) public {

        uint256 eggId = ownerToThunderEggId[msg.sender];
        require(eggId != 0, "No ThunderEgg!");

        updateSacredGrove(_groveId);

        SacredGrove storage pool = sacredGrove[_groveId];
        ThunderEggInfo storage info = thunderEggInfoMapping[_groveId][eggId];

        // burn the token - send all rewards and LP back!
        _burn(_groveId, eggId);

        // pay out rewards from the ThunderEgg
        uint256 pending = info.amount.mul(pool.accLavaPerShare).div(1e18).sub(info.rewardDebt);
        if (pending > 0) {
            safeLavaTransfer(msg.sender, pending);
        }

        // send all LP back...
        pool.lpToken.safeTransfer(address(msg.sender), info.amount);

        info.rewardDebt = info.amount.mul(pool.accLavaPerShare).div(1e18);
        emit Withdraw(msg.sender, _groveId, info.amount);
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeLavaTransfer(address _to, uint256 _amount) internal {
        uint256 lavaBal = lava.balanceOf(address(this));
        if (_amount > lavaBal) {
            lava.transfer(_to, lavaBal);
        } else {
            lava.transfer(_to, _amount);
        }
    }

    // *** ERC721 functions below

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function _checkOnERC721Received(address from, address to, uint256 eggId, bytes memory _data) private returns (bool) {
        if (!isContract(to)) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                eggId,
                _data
            ));

        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == ERC721_RECEIVED);
        }

        return true;
    }

    function setGodsOffering(uint256 _godsOffering) external onlyGod {
        godsOffering = _godsOffering;
    }

    function setBaseTokenURI(string calldata _uri) external onlyGod {
        baseTokenURI = _uri;
    }

    function setName(uint256 _eggId, bytes32 _name) external onlyGod {
        thunderEggIdToName[_eggId] = _name;
    }

    function _mint(uint256 _groveId, address _to, bytes32 _name) internal returns (uint256) {
        require(_to != address(0), "ERC721: mint to the zero address");

        SacredGrove storage grove = sacredGrove[_groveId];
        require(grove.endBlock >= block.number, 'This grove is not longer fertile');

        tokenPointer = tokenPointer.add(1);
        uint256 eggId = tokenPointer;

        // Mint
        thunderEggIdToOwner[eggId] = _to;
        ownerToThunderEggId[msg.sender] = eggId;

        // birth
        thunderEggIdToBirth[eggId] = block.number;

        // name
        thunderEggIdToName[eggId] = _name;

        // MetaData
        grove.totalSupply = grove.totalSupply.add(1);
        totalSupply = totalSupply.add(1);
        totalSpawned = totalSpawned.add(1);

        // Single Transfer event for a single token
        emit Transfer(address(0), _to, eggId);

        return eggId;
    }

    function exists(uint256 _eggId) external view returns (bool) {
        return _exists(_eggId);
    }

    function _exists(uint256 _eggId) internal view returns (bool) {
        return thunderEggIdToOwner[_eggId] != address(0);
    }

    function tokenURI(uint256 _eggId) external view returns (string memory) {
        require(_exists(_eggId), "ERC721Metadata: URI query for nonexistent token");
        return Strings.strConcat(baseTokenURI, Strings.uint2str(_eggId));
    }

    function _burn(uint256 _groveId, uint256 _eggId) internal {
        require(_exists(_eggId), "must exist");

        address owner = thunderEggIdToOwner[_eggId];

        require(owner == msg.sender, "Must own the egg!");

        SacredGrove storage pool = sacredGrove[_groveId];

        thunderEggIdToOwner[_eggId] = address(0);
        ownerToThunderEggId[msg.sender] = 0;

        pool.totalSupply = pool.totalSupply.sub(1);
        totalSupply = totalSupply.sub(1);
        totalDestroyed = totalDestroyed.add(1);

        emit Transfer(
            owner,
            address(0),
            _eggId
        );
    }

    function safeTransferFrom(address _from, address _to, uint256 _eggId) override public {
        safeTransferFrom(_from, _to, _eggId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _eggId, bytes memory _data) override public {
        transferFrom(_from, _to, _eggId);
        require(_checkOnERC721Received(_from, _to, _eggId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function approve(address _approved, uint256 _eggId) override external {
        address owner = ownerOf(_eggId);
        require(_approved != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        approvals[_eggId] = _approved;
        emit Approval(
            owner,
            _approved,
            _eggId
        );
    }

    function setApprovalForAll(address _operator, bool _approved) override external {
        require(_operator != msg.sender, "ERC721: approve to caller");

        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(
            msg.sender,
            _operator,
            _approved
        );
    }

    function balanceOf(address _owner) override external view returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return ownerToThunderEggId[_owner] != 0 ? 1 : 0;
    }

    function transferFrom(address _from, address _to, uint256 _eggId) override public {
        require(
            _to != address(0),
            "ERC721: transfer to the zero address"
        );

        address owner = ownerOf(_eggId);
        require(
            _from == owner,
            "ERC721: transfer of token that is not own"
        );

        address spender = msg.sender;
        address approvedAddress = getApproved(_eggId);
        require(
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            approvedAddress == spender,
            "ERC721: transfer caller is not owner nor approved"
        );

        if (approvedAddress != address(0)) {
            approvals[_eggId] = address(0);
        }

        emit Approval(owner, address(0), _eggId);

        thunderEggIdToOwner[_eggId] = _to;
        ownerToThunderEggId[_from] = 0;
        ownerToThunderEggId[_to] = _eggId;

        emit Transfer(
            _from,
            _to,
            _eggId
        );
    }

    function ownerOf(uint256 _eggId) override public view returns (address) {
        require(_exists(_eggId), "ERC721: operator query for nonexistent token");
        return thunderEggIdToOwner[_eggId];
    }

    function getApproved(uint256 _eggId) override public view returns (address) {
        require(_exists(_eggId), "ERC721: approved query for nonexistent token");
        return approvals[_eggId];
    }

    function isApprovedForAll(address _owner, address _operator) override public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
}
