/**
 *Submitted for verification at FtmScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function circulatingSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );
}

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyPolicy {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyPolicy
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract IRedeemHelper {
    address[] public bonds;
}

contract LuxorSupply is Ownable {
    uint public totalLuxor;
    uint public circulatingLuxor;

    uint public daoLuxor;
    uint public pooledLuxor;

    uint public mintableLuxor;
    uint public stakedLuxor;

    address public immutable DAO = 0xcB5ba2079C7E9eA6571bb971E383Fe5D59291a95;
    address public immutable LUX_DAI =
        0x46729c2AeeabE7774a0E710867df80a6E19Ef851;
    address public immutable LUX_FTM =
        0x951BBB838e49F7081072895947735b0892cCcbCD;

    IRedeemHelper public immutable RedeemHelper =
        IRedeemHelper(0xc7c9A5789759C61c1469b81990e1380C8fB84e5D);

    // bond addresses
    address[] public bonds;

    IERC20 public immutable LUX =
        IERC20(0x6671E20b83Ba463F270c8c75dAe57e3Cc246cB2b);

    IERC20 public immutable LUM =
        IERC20(0x4290b33158F429F40C0eDc8f9b9e5d8C5288800c);

    function getStats()
        public
        view
        returns (
            uint total,
            uint circulating,
            uint dao,
            uint pooled,
            uint mintable,
            uint staked
        )
    {
        return (
            totalLuxor,
            circulatingLuxor,
            daoLuxor,
            pooledLuxor,
            mintableLuxor,
            stakedLuxor
        );
    }

    function updateStats() public {
        totalLuxor = LUX.totalSupply();
        daoLuxor = LUX.balanceOf(DAO);
        pooledLuxor = LUX.balanceOf(LUX_DAI) + LUX.balanceOf(LUX_FTM);
        mintableLuxor = getMintable();
        stakedLuxor = LUM.circulatingSupply();

        circulatingLuxor = totalLuxor - daoLuxor - pooledLuxor - stakedLuxor;
    }

    function getMintable() public view returns (uint pending) {
        for (uint i = 0; i < bonds.length; i++) {
            if (LUX.balanceOf(bonds[i]) > 0) {
                pending += LUX.balanceOf(bonds[i]);
            }
        }
    }

    function addBondContract(address _bond) external onlyPolicy {
        require(_bond != address(0));
        bonds.push(_bond);
    }

    function removeBondContract(uint _index) external onlyPolicy {
        bonds[_index] = address(0);
    }
}