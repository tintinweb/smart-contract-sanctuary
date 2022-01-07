/**
 *Submitted for verification at FtmScan.com on 2022-01-07
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

interface IBondDepository {
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint minimumPrice; // vs principle value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    struct Bond {
        uint payout; // HEC remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
    }

    function percentVestedFor( address _depositor ) external view returns ( uint percentVested_ );
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ );

    function bondPrice() external view returns ( uint );
    function bondPriceInUSD() external view returns ( uint );
    function maxPayout() external view returns ( uint );
    function standardizedDebtRatio() external view returns ( uint );

    function terms() external view returns (Terms memory);
    function totalDebt() external view returns (uint);

    function bondInfo(address _depositor) external view returns ( Bond memory _info );
}

interface IBondv2Depository {
    struct Bond {
        uint payout; // HEC remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
    }
 
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

    function bondInfo(address _depositor) external view returns ( Bond memory _info );
}

interface IBondStakeDepository {
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
    function bondInfo(address _depositor) external view returns ( uint payout,uint vesting,uint lastBlock,uint pricePaid );
}

contract Aggregator is Ownable {
    struct BondTerms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint minimumPrice; // vs principle value , 4 decimals 0.15 = 1500
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    struct GlobalBondData {
        string Name;
        address Contract;

        Aggregator.BondTerms BondTerms;
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

        Aggregator.BondInfo Info;
        uint PercentVested;
        uint PendingPayout;
    }

    address[] public Bonds_11;
    address[] public Bonds_11v2;
    address[] public Bonds_44;

    constructor(
    ) {
    }

    function globalBondData() public view returns (GlobalBondData[] memory) {
        GlobalBondData[] memory _data = new GlobalBondData[]( (Bonds_11.length + Bonds_11v2.length + Bonds_44.length) );

        uint index=0;
        for(uint i=0;i<Bonds_11.length;i++) {
            IBondDepository bond = IBondDepository(Bonds_11[i]);

            IBondDepository.Terms memory terms = bond.terms();

            _data[index] = GlobalBondData({
                    Name: "",
                    Contract: Bonds_11[i],
                    
                    BondTerms: Aggregator.BondTerms({
                        controlVariable: terms.controlVariable,
                        vestingTerm: terms.vestingTerm,
                        minimumPrice: terms.minimumPrice,
                        maxPayout: terms.maxPayout,
                        fee: terms.fee,
                        maxDebt: terms.maxDebt
                    }),
                    MaxPayout: bond.maxPayout(),
                    StandardizedDebtRatio: bond.standardizedDebtRatio(),
                    TotalDebt: bond.totalDebt(),
                    BondPriceInUSD: bond.bondPriceInUSD(),
                    TotalPrinciple: 0
                });

            index++;
        }

        for(uint i=0;i<Bonds_11v2.length;i++) {
            IBondv2Depository bond = IBondv2Depository(Bonds_11v2[i]);

            IBondv2Depository.Terms memory terms = bond.terms();

            _data[index] = GlobalBondData({
                    Name: bond.name(),
                    Contract: Bonds_11v2[i],
                    
                    BondTerms: Aggregator.BondTerms({
                        controlVariable: terms.controlVariable,
                        vestingTerm: terms.vestingTerm,
                        minimumPrice: terms.minimumPrice,
                        maxPayout: terms.maxPayout,
                        fee: terms.fee,
                        maxDebt: terms.maxDebt
                    }),
                    MaxPayout: bond.maxPayout(),
                    StandardizedDebtRatio: bond.standardizedDebtRatio(),
                    TotalDebt: bond.totalDebt(),
                    BondPriceInUSD: bond.bondPriceInUSD(),
                    TotalPrinciple: bond.totalPrinciple()
                });

            index++;
        }

        for(uint i=0;i<Bonds_44.length;i++) {
            IBondStakeDepository bond = IBondStakeDepository(Bonds_44[i]);

            IBondStakeDepository.Terms memory terms = bond.terms();

            _data[index] = GlobalBondData({
                    Name: bond.name(),
                    Contract: Bonds_44[i],
                    
                    BondTerms: Aggregator.BondTerms({
                        controlVariable: terms.controlVariable,
                        vestingTerm: terms.vestingTerm,
                        minimumPrice: terms.minimumPrice,
                        maxPayout: terms.maxPayout,
                        fee: terms.fee,
                        maxDebt: terms.maxDebt
                    }),
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
        UserBondData[] memory _data = new UserBondData[]((Bonds_11.length + Bonds_11v2.length + Bonds_44.length));

        uint index=0;
        for(uint i=0;i<Bonds_11.length;i++) {
            IBondDepository bond = IBondDepository(Bonds_11[i]);

            IBondDepository.Bond memory info = bond.bondInfo(_depositor);

            _data[index] = UserBondData({
                    Name: "",
                    Contract: Bonds_11[i],

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

        for(uint i=0;i<Bonds_11v2.length;i++) {
            IBondv2Depository bond = IBondv2Depository(Bonds_11v2[i]);

            IBondv2Depository.Bond memory info = bond.bondInfo(_depositor);

            _data[index] = UserBondData({
                    Contract: Bonds_11v2[i],
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

    function add11BondContract(address _contract) external onlyPolicy() {
        require(_contract != address(0));

        for(uint i=0;i<Bonds_11.length;i++) {
            if(Bonds_11[i] == _contract) {
                return;
            }
        }

        Bonds_11.push(_contract);
    }

    function add11v2BondContract(address _contract) external onlyPolicy() {
        require(_contract != address(0));

        for(uint i=0;i<Bonds_11v2.length;i++) {
            if(Bonds_11v2[i] == _contract) {
                return;
            }
        }

        Bonds_11v2.push(_contract);
    }

    function add44BondContract(address _contract) external onlyPolicy() {
        require(_contract != address(0));

        for(uint i=0;i<Bonds_44.length;i++) {
            if(Bonds_44[i] == _contract) {
                return;
            }
        }

        Bonds_44.push(_contract);
    }

    function remove11BondContract(address _contract) external onlyPolicy() {
        require(_contract != address(0));

        for(uint i=0;i<Bonds_11.length;i++) {
            if(Bonds_11[i] == _contract) {
                for(uint j=i;j<Bonds_11.length-1;j++) {
                    Bonds_11[j] = Bonds_11[j+1];
                }

                Bonds_11.pop();
            }
        }

    }

    function remove11v2BondContract(address _contract) external onlyPolicy() {
        require(_contract != address(0));

        for(uint i=0;i<Bonds_11v2.length;i++) {
            if(Bonds_11v2[i] == _contract) {
                for(uint j=i;j<Bonds_11v2.length-1;j++) {
                    Bonds_11v2[j] = Bonds_11v2[j+1];
                }

                Bonds_11v2.pop();
            }
        }

    }

    function remove44BondContract(address _contract) external onlyPolicy() {
        require(_contract != address(0));

        for(uint i=0;i<Bonds_44.length;i++) {
            if(Bonds_44[i] == _contract) {
                for(uint j=i;j<Bonds_44.length-1;j++) {
                    Bonds_44[j] = Bonds_44[j+1];
                }

                Bonds_44.pop();
            }
        }

    }

}