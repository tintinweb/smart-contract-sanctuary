// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;
pragma abicoder v2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ITreasury.sol";
import "./IgOHM.sol";
import "./IStaking.sol";
import "./Ownable.sol";

interface IClaim {
    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 wClaimed; // static number
        uint256 max; // maximum nominal OHM amount can claim
    }
    function terms(address _address) external view returns (Term memory);
}

/**
 *  This contract allows Olympus seed investors and advisors to claim tokens.
 *  It has been revised to consider claims as staked immediately for accounting purposes.
 *  This ensures that network ownership does not exceed disclosed levels.
 *  Claimants remain protected from network dilution that may arise, but claim and stake
 *  does not allow them to grow ownership beyond predefined levels. This change also penalizes
 *  sellers, since the tokens sold are still considered staked within this contract. This  
 *  step was taken to ensure fair distribution of exposure in the network.  
 */
contract InvestorClaimV2 is Ownable {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 gClaimed; // rebase-agnostic number
        uint256 max; // maximum nominal OHM amount can claim
    }

    /* ========== STATE VARIABLES ========== */
    
    // claim token
    IERC20 internal immutable ohm = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5); 
    // payment token
    IERC20 internal immutable dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); 
    // mints claim token
    ITreasury internal immutable treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef); 
    // stake OHM for sOHM
    IStaking internal immutable staking = IStaking(0xB63cac384247597756545b500253ff8E607a8020); 
    // holds non-circulating supply
    address internal immutable dao = 0x245cc372C84B3645Bf0Ffe6538620B04a217988B; 
    // tracks rebase-agnostic balance
    IgOHM internal immutable gOHM = IgOHM(0x0ab87046fBb341D058F17CBC4c1133F25a20a52f);
    // previous deployment of contract (to migrate terms)
    IClaim internal immutable previous = IClaim(0xaCCC8306455BaA01593Fa6267809fEA72F684169);

    // tracks address info
    mapping( address => Term ) public terms;
    // facilitates address change
    mapping( address => address ) public walletChange;
    // as percent of supply (4 decimals: 10000 = 1%)
    uint256 public totalAllocated;
    // maximum portion of supply can allocate. == 4%
    uint256 public maximumAllocated = 40000; 
    
    constructor() {}

    /* ========== MUTABLE FUNCTIONS ========== */
    
    /**
     * @notice allows wallet to claim OHM
     * @param _to address
     * @param _amount uint256
     */
    function claim(address _to, uint256 _amount) external {
        ohm.safeTransfer(_to, _claim(_amount));
    }

    /**
     * @notice allows wallet to claim OHM and stake. set _claim = true if warmup is 0.
     * @param _to address
     * @param _amount uint256
     * @param _rebasing bool
     * @param _claimFromStaking bool
     */
    function stake(address _to, uint256 _amount, bool _rebasing, bool _claimFromStaking) external {
        staking.stake(_to, _claim(_amount), _rebasing, _claimFromStaking);
    }

    /**
     * @notice logic for claiming OHM
     * @param _amount uint256
     * @return toSend_ uint256
     */
    function _claim(uint256 _amount) internal returns (uint256 toSend_) {
        Term memory info = terms[msg.sender];

        dai.safeTransferFrom(msg.sender, address(this), _amount);
        toSend_ = treasury.deposit(_amount, address(dai), 0);

        require(redeemableFor(msg.sender).div(1e9) >= toSend_, "Claim more than vested");
        require(info.max.sub(claimed(msg.sender)) >= toSend_, "Claim more than max");

        terms[msg.sender].gClaimed = info.gClaimed.add(gOHM.balanceTo(toSend_));
    }

    /**
     * @notice allows address to push terms to new address
     * @param _newAddress address
     */
    function pushWalletChange(address _newAddress) external {
        require(terms[msg.sender].percent != 0, "No wallet to change");
        walletChange[msg.sender] = _newAddress;
    }
    
    /**
     * @notice allows new address to pull terms
     * @param _oldAddress address
     */
    function pullWalletChange(address _oldAddress) external {
        require(walletChange[_oldAddress] == msg.sender, "Old wallet did not push");
        require(terms[msg.sender].percent != 0, "Wallet already exists");
        
        walletChange[_oldAddress] = address(0);
        terms[msg.sender] = terms[_oldAddress];
        delete terms[_oldAddress];
    }

    /**
     * @notice mass approval saves gas
     */
    function approve() external {
        ohm.approve(address(staking), 1e33);
        dai.approve(address(treasury), 1e33);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice view OHM claimable for address. DAI decimals (18).
     * @param _address address
     * @return uint256
     */
    function redeemableFor( address _address ) public view returns (uint) {
        Term memory info = terms[ _address ];
        uint max = circulatingSupply().mul( info.percent ).div( 1e6 );
        if (max > info.max) max = info.max;
        return max.sub( claimed( _address ) ).mul( 1e9 );
    }

    /**
     * @notice view OHM claimed by address. OHM decimals (9).
     * @param _address address
     * @return uint256
     */
    function claimed(address _address) public view returns (uint256) {
        return gOHM.balanceFrom(terms[_address].gClaimed);
    }

    /**
     * @notice view circulating supply of OHM
     * @notice calculated as total supply minus DAO holdings
     * @return uint256
     */
    function circulatingSupply() public view returns (uint256) {
        return treasury.baseSupply().sub(ohm.balanceOf(dao));
    }  

    /* ========== OWNER FUNCTIONS ========== */

    /**
     * @notice bulk migrate users from previous contract
     * @param _addresses address[] memory
     */
    function migrate(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            IClaim.Term memory term = previous.terms(_addresses[i]);
            setTerms(
                _addresses[i], 
                term.percent,
                term.wClaimed,
                term.max
            );
        }
    }

    /**
     *  @notice set terms for new address
     *  @notice cannot lower for address or exceed maximum total allocation
     *  @param _address address
     *  @param _percent uint256
     *  @param _gClaimed uint256
     *  @param _max uint256
     */
    function setTerms(
        address _address, 
        uint256 _percent, 
        uint256 _gClaimed, 
        uint256 _max
    ) public onlyOwner {
        require(terms[_address].max == 0, "address already exists");
        terms[_address] = Term({
            percent: _percent,
            gClaimed: _gClaimed,
            max: _max
        });
        require(totalAllocated.add(_percent) <= maximumAllocated, "Cannot allocate more");
        totalAllocated = totalAllocated.add(_percent);
    }
}