// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Migratable.sol';

contract Wormhole is Migratable {

    event Freeze (
        address indexed account,
        uint256 amount,
        uint256 fromChainId,
        address fromWormhole,
        uint256 toChainId,
        address toWormhole,
        uint256 nonce,
        uint256 timestamp
    );

    event Claim (
        address indexed account,
        uint256 amount,
        uint256 fromChainId,
        address fromWormhole,
        uint256 toChainId,
        address toWormhole,
        uint256 nonce,
        uint256 timestamp
    );

    string public constant name = 'Wormhole';

    address public tokenAddress;

    bool public allowMintBurn;

    uint256 public nonce;

    uint256 public chainId;

    mapping (bytes32 => bool) public usedHash;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    bytes32 public constant CLAIM_TYPEHASH = keccak256(
        'Claim(address account,uint256 amount,uint256 fromChainId,address fromWormhole,uint256 toChainId,address toWormhole,uint256 nonce)'
    );

    constructor (address tokenAddress_, bool allowMintBurn_) {
        controller = msg.sender;
        tokenAddress = tokenAddress_;
        allowMintBurn = allowMintBurn_;
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
    }

    function approveMigration() public override _controller_ _valid_ {
        require(migrationTimestamp != 0 && block.timestamp >= migrationTimestamp, 'Wormhole.approveMigration: migrationTimestamp not met yet');
        if (allowMintBurn) {
            IERC20(tokenAddress).setController(migrationDestination);
        } else {
            IERC20(tokenAddress).approve(migrationDestination, type(uint256).max);
        }
        isMigrated = true;

        emit ApproveMigration(migrationTimestamp, address(this), migrationDestination);
    }

    function executeMigration(address source) public override _controller_ _valid_ {
        uint256 _migrationTimestamp = IWormhole(source).migrationTimestamp();
        address _migrationDestination = IWormhole(source).migrationDestination();
        require(_migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp, 'Wormhole.executeMigration: migrationTimestamp not met yet');
        require(_migrationDestination == address(this), 'Wormhole.executeMigration: not destination address');

        if (!IWormhole(source).allowMintBurn()) {
            IERC20(tokenAddress).transferFrom(source, address(this), IERC20(tokenAddress).balanceOf(source));
        }

        emit ExecuteMigration(_migrationTimestamp, source, address(this));
    }

    function freeze(uint256 amount, uint256 toChainId, address toWormhole) public _valid_ {
        require(amount > 0, 'Wormhole.freeze: 0 amount');
        require(toChainId != chainId, 'Wormhole.freeze: to the same chain');
        if (allowMintBurn) {
            IERC20(tokenAddress).burn(msg.sender, amount);
        } else {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }
        emit Freeze(msg.sender, amount, chainId, address(this), toChainId, toWormhole, nonce++, block.timestamp);
    }

    function claim(uint256 amount, uint256 fromChainId, address fromWormhole, uint256 fromNonce, uint8 v, bytes32 r, bytes32 s) public _valid_ {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), chainId, address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, msg.sender, amount, fromChainId, fromWormhole, chainId, address(this), fromNonce));
        require(!usedHash[structHash], 'Wormhole.claim: replay');
        usedHash[structHash] = true;

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == controller, 'Wormhole.claim: unauthorized');

        if (allowMintBurn) {
            IERC20(tokenAddress).mint(msg.sender, amount);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }

        emit Claim(msg.sender, amount, fromChainId, fromWormhole, chainId, address(this), fromNonce, block.timestamp);
    }

}

interface IERC20 {
    function setController(address newController) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address account, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

interface IWormhole {
    function migrationTimestamp() external view returns (uint256);
    function migrationDestination() external view returns (address);
    function allowMintBurn() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Migratable {

    event PrepareMigration(uint256 migrationTimestamp, address source, address destination);

    event ApproveMigration(uint256 migrationTimestamp, address source, address destination);

    event ExecuteMigration(uint256 migrationTimestamp, address source, address destination);

    address public controller;

    uint256 public migrationTimestamp;

    address public migrationDestination;

    bool public isMigrated;

    modifier _controller_() {
        require(msg.sender == controller, 'Migratable._controller_: can only called by controller');
        _;
    }

    modifier _valid_() {
        require(!isMigrated, 'Migratable._valid_: cannot proceed, this contract has been migrated');
        _;
    }

    function setController(address newController) public _controller_ _valid_ {
        require(newController != address(0), 'Migratable.setController: to 0 address');
        controller = newController;
    }

    function prepareMigration(address destination, uint256 graceDays) public _controller_ _valid_ {
        require(destination != address(0), 'Migratable.prepareMigration: to 0 address');
        require(graceDays >= 3 && graceDays <= 365, 'Migratable.prepareMigration: graceDays must be 3-365 days');

        migrationTimestamp = block.timestamp + graceDays * 1 days;
        migrationDestination = destination;

        emit PrepareMigration(migrationTimestamp, address(this), migrationDestination);
    }

    function approveMigration() public virtual;

    function executeMigration(address source) public virtual;

}