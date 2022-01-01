/**
 *Submitted for verification at FtmScan.com on 2021-12-31
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

interface IHectorBondStakeDepository {
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint minimumPrice; // vs principle value , 4 decimals 0.15 = 1500
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    function name() external view returns (string memory);

    function bondInfo(address _depositor) external view returns ( uint payout,uint vesting,uint lastBlock,uint pricePaid );
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

contract Aggregator is Ownable {

    struct GlobalBondData {
        address Contract;
        string Name;

        //IHectorBondStakeDepository.Terms BondTerms;
        //uint MaxPayout;
        //uint StandardizedDebtRatio;
        //uint TotalDebt;
        //uint BondPriceInUSD;
        //uint TotalPrinciple;
        
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
        //bondInfo, percentVestedFor, pendingPayoutFor
    }

    constructor(
    ) {
    }

    function globalBondData(address[] memory _contracts) public view returns (GlobalBondData[] memory) {

        GlobalBondData[] memory _data = new GlobalBondData[](_contracts.length);
        for(uint i=0;i<_contracts.length;i++) {
            IHectorBondStakeDepository bond = IHectorBondStakeDepository(_contracts[i]);

            //bond.terms();
            _data[i] = GlobalBondData({
                    Contract: _contracts[i],
                    Name: bond.name()

                    //BondTerms: bond.terms(),
                    //MaxPayout: bond.maxPayout(),
                    //StandardizedDebtRatio: bond.standardizedDebtRatio(),
                    //TotalDebt: bond.totalDebt(),
                    //BondPriceInUSD: bond.bondPriceInUSD(),
                    //TotalPrinciple: bond.totalPrinciple()
                });
        }

        return _data;
    }

    function perUserBondData(address[] memory _contracts, address _depositor) public view returns (UserBondData[] memory _data) {
        _data = new UserBondData[](_contracts.length);

        for(uint i=0;i<_contracts.length;i++) {
            IHectorBondStakeDepository bond = IHectorBondStakeDepository(_contracts[i]);

            ( uint payout,uint vesting,uint lastBlock,uint pricePaid ) = bond.bondInfo(_depositor);
            
            _data[i] = UserBondData({
                    Contract: _contracts[i],
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
        }

        return _data;
    }
}