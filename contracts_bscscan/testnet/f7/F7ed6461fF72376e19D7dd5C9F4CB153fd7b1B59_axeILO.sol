// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./types/AccessControlled.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IERC20.sol";

contract axeILO is AccessControlled {

    /* ======== STATE VARIABLES ======== */

    address public AXE; // token given as payment for bond
    address public principle; // token used to create bond
    address public treasury; // mints AXE when receives principle
    address public staking; // to auto-stake payout
    uint public maxTotal; // max AXE to be minted
    uint public total = 0; // total AXE minted
    uint public maxPayout; // maximum no. of AXEs that one person can buy
    uint public price; // fixed price of the bond

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    /* ======== STRUCTS ======== */

    // Info for bond holder
    struct Bond {
        uint payout; // AXE remaining to be paid
        uint lastBlock; // Last interaction
    }

    /* ======== INITIALIZATION ======== */

    constructor (
        address _authority,
        address _principle
    )
    AccessControlled(IAuthority(_authority)) {
        AXE = authority.get('axe');
        treasury = authority.get('treasury');
        staking = authority.get('staking');
        require( _principle != address(0) );
        principle = _principle;
        maxTotal = 100000 * 10**9; // 100k AXE
        maxPayout = 500 * 10**9; // 500 AXE
        price = 10; // 1 AXE = 10 BUSD
    }


    /* ======== POLICY FUNCTIONS ======== */

    function setTerms(
      uint256 _maxTotal,
      uint256 _maxPayout,
      uint256 _price
    ) external onlyGovernor {
        maxTotal = _maxTotal;
        maxPayout = _maxPayout;
        price = _price;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @return uint
     */
    function deposit(uint _amount) external returns ( uint ) {

        uint256 payout = payoutFor(_amount); // payout to bonder is computed
        require( total + payout <= maxTotal, "Max capacity reached" );
        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 AXE ( underflow protection )
        require( payout <= maxPayout, "Bond too large"); // size protection because there is no slippage

        IERC20( principle ).transferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( treasury ), _amount );
        ITreasury( treasury ).deposit( _amount, principle, 0 );

        total += payout;

        // depositor info is stored
        bondInfo[ msg.sender ] = Bond({
            payout: bondInfo[ msg.sender ].payout + payout,
            lastBlock: block.number
        });

        // uint256 reward = _payout * 10 / 100; // 10% for liquidity
        // ITreasury( treasury ).mint( authority.get('governor') , _payout.add(reward));

        IERC20( principle ).approve( address( staking ), payout );
        IStaking( staking ).stake( msg.sender, payout );

        return payout;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */


    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return _value * 10**9 / 10**18 / price;
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or AXE) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != AXE );
        require( _token != principle );
        IERC20( _token ).transfer( authority.get('governor'), IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthority.sol";

abstract contract AccessControlled {
    event AuthorityUpdated(IAuthority indexed authority);
    string UNAUTHORIZED = "UNAUTHORIZED";
    IAuthority public authority;
    constructor(IAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    modifier onlyGovernor() {
        require(msg.sender == authority.get('governor'), UNAUTHORIZED);
        _;
    }
    modifier onlyTreasury() {
        require(msg.sender == authority.get('treasury'), UNAUTHORIZED);
        _;
    }
    modifier onlyStaking() {
        require(msg.sender == authority.get('staking'), UNAUTHORIZED);
        _;
    }
    function setAuthority(IAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(uint256 _amount, address _token, uint256 _profit) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IStaking {
    function stake(address _to, uint256 _amount) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function unstake(address _to, uint256 _amount) external returns (uint256);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
interface IAuthority {
    function get(string memory _role) external view returns (address);
}