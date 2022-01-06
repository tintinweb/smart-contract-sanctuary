/**
 *Submitted for verification at FtmScan.com on 2022-01-06
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}
interface IDepository {
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint minimumPrice; // vs principle value , 4 decimals 0.15 = 1500
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }
    function name() external view returns (string memory);

    function percentVestedFor( address _depositor ) external view returns ( uint percentVested_ );
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ );

    function bondPrice() external view returns ( uint );
    function bondPriceInUSD() external view returns ( uint );
    function maxPayout() external view returns ( uint );
    function standardizedDebtRatio() external view returns ( uint );

    function terms() external view returns (Terms memory);
    function totalDebt() external view returns (uint);
    function totalPrinciple() external view returns (uint);
}

interface IBondDepository is IDepository {
    struct Bond {
        uint payout; // HEC remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
    }
 
    function bondInfo(address _depositor) external view returns ( Bond memory _info );
}

interface IBondStakeDepository is IDepository {
    function bondInfo(address _depositor) external view returns ( uint payout,uint vesting,uint lastBlock,uint pricePaid );
}

contract Aggregator is Ownable {
    struct GlobalBondData {
        string Name;
        address Contract;

        IDepository.Terms BondTerms;
        uint MaxPayout;
        uint StandardizedDebtRatio;
        uint TotalDebt;
        uint BondPriceInUSD;
        uint TotalPrinciple;
        
    }
    struct BondInfo {
        uint Payout;
        uint Vesting;
        uint LastBlock;
        uint PricePaid;
    }
    struct UserBondData {
        address Contract;
        string Name;

        BondInfo Info;
        uint PercentVested;
        uint PendingPayout;
    }

    address[] public Bonds_11;
    address[] public Bonds_44;

    constructor(
        address[] memory _bonds_11,
        address[] memory _bonds_44
    ) {
        Bonds_11 = _bonds_11;
        Bonds_44 = _bonds_44;
    }

    function addBondContract(address _contract, bool _is11) external onlyPolicy() {
        require(_contract != address(0));

        if(_is11) {
            Bonds_11.push(_contract);
        }
        else {
            Bonds_44.push(_contract);
        }
    }

    function globalBondData() public view returns (GlobalBondData[] memory) {
        GlobalBondData[] memory _data = new GlobalBondData[](Bonds_11.length+Bonds_44.length);

        uint index=0;
        for(uint i=0;i<Bonds_11.length;i++) {
            IDepository bond = IDepository(Bonds_11[i]);

            _data[index] = GlobalBondData({
                    Name: bond.name(),
                    Contract: Bonds_11[i],
                    
                    BondTerms: bond.terms(),
                    MaxPayout: bond.maxPayout(),
                    StandardizedDebtRatio: bond.standardizedDebtRatio(),
                    TotalDebt: bond.totalDebt(),
                    BondPriceInUSD: bond.bondPriceInUSD(),
                    TotalPrinciple: bond.totalPrinciple()
                });

            index++;
        }

        for(uint i=0;i<Bonds_44.length;i++) {
            IDepository bond = IDepository(Bonds_44[i]);

            _data[index] = GlobalBondData({
                    Name: bond.name(),
                    Contract: Bonds_44[i],
                    
                    BondTerms: bond.terms(),
                    MaxPayout: bond.maxPayout(),
                    StandardizedDebtRatio: bond.standardizedDebtRatio(),
                    TotalDebt: bond.totalDebt(),
                    BondPriceInUSD: bond.bondPriceInUSD(),
                    TotalPrinciple: bond.totalPrinciple()
                });

            index++;
        }

        return _data;
    }

    function perUserBondData(address _depositor) public view returns (UserBondData[] memory) {
        UserBondData[] memory _data = new UserBondData[](Bonds_11.length+Bonds_44.length);

        uint index=0;
        for(uint i=0;i<Bonds_11.length;i++) {
            IBondDepository bond = IBondDepository(Bonds_11[i]);

            IBondDepository.Bond memory info = bond.bondInfo(_depositor);

            _data[index] = UserBondData({
                    Contract: Bonds_11[i],
                    Name: bond.name(),

                    Info: BondInfo({
                        Payout: info.payout,
                        Vesting: info.vesting,
                        LastBlock: info.lastBlock,
                        PricePaid: info.pricePaid
                    }),

                    PercentVested: bond.percentVestedFor(_depositor),
                    PendingPayout: bond.pendingPayoutFor(_depositor)
                });
            index++;
        }

        for(uint i=0;i<Bonds_44.length;i++) {
            IBondStakeDepository bond = IBondStakeDepository(Bonds_44[i]);

            ( uint payout,uint vesting,uint lastBlock,uint pricePaid ) = bond.bondInfo(_depositor);

            _data[index] = UserBondData({
                    Contract: Bonds_44[i],
                    Name: bond.name(),

                    Info: BondInfo({
                        Payout: payout,
                        Vesting: vesting,
                        LastBlock: lastBlock,
                        PricePaid: pricePaid
                    }),

                    PercentVested: bond.percentVestedFor(_depositor),
                    PendingPayout: bond.pendingPayoutFor(_depositor)
                });
            index++;
        }

        return _data;
    }
}