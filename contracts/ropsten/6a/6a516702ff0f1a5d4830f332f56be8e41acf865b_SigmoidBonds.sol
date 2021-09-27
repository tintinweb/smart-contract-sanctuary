/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC659 {
   struct ERC20LOAN  {

        // If auction clossed =false, if ongoing =true
        bool auctionStatus;

        // seller address
        address payable seller;
        
        address payable buyer;

        // starting price
        uint256 startingPrice;

        // min price
        uint256 endingPrice;

        // Auction started at
        uint256 auctionTimestamp;

        // Auction duration
        uint256 auctionDuration;

        // // bond address of tge auction
        address bondAddress;

        uint256 interestRate;

        uint256 loanDuration;
        uint256 amount;
        // Bonds
        uint256[] bondClass;

        // Bonds
        uint256[] bondNonce;

        // Bonds
        uint256[] bondAmount;

    }
    struct BondTypes {
        address bondAddress;
        uint256 eta;
        uint256[] bondAmount;
        uint256[] bondClass;
        uint256[] bondNonce;
    }

    struct BondLib {
        string types;
        BondTypes bonds;
        ERC20LOAN erc20loans;
    }

    function totalSupply(uint256 class, uint256 nonce)
        external
        view
        returns (uint256);

    function activeSupply(uint256 class, uint256 nonce)
        external
        view
        returns (uint256);

    function burnedSupply(uint256 class, uint256 nonce)
        external
        view
        returns (uint256);

    function redeemedSupply(uint256 class, uint256 nonce)
        external
        view
        returns (uint256);

    function batchActiveSupply(uint256 class) external view returns (uint256);

    function batchBurnedSupply(uint256 class) external view returns (uint256);

    function batchRedeemedSupply(uint256 class) external view returns (uint256);

    function batchTotalSupply(uint256 class) external view returns (uint256);

    function getNonceCreated(uint256 class)
        external
        view
        returns (uint256[] memory);

    function getClassCreated() external view returns (uint256[] memory);

    function balanceOf(
        address account,
        uint256 class,
        uint256 nonce
    ) external view returns (uint256);

    function batchBalanceOf(address account, uint256 class)
        external
        view
        returns (uint256[] memory);

    function totalBatchBalanceOf(address account, uint256 class)
        external
        view
        returns (uint256);

    function getBondSymbol(uint256 class) external view returns (string memory);

    function getBondInfo(uint256 class, uint256 nonce)
        external
        view
        returns (
            string memory BondSymbol,
            uint256 timestamp,
            uint256 info2,
            uint256 info3,
            uint256 info4,
            uint256 info5,
            uint256 info6
        );

    function getBondProgress(uint256 class, uint256 nonce)
        external
        view
        returns (uint256[2] memory);

    function getBatchBondProgress(uint256 class, uint256 nonce)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function bondIsRedeemable(uint256 class, uint256 nonce)
        external
        view
        returns (bool);

    function writeInfo(ERC20LOAN calldata _ERC20Loan) external returns (bool);

    function issueBond(
        address _to,
        uint256 class,
        uint256 _amount
    ) external returns (bool);

    function issueNFTBond(
        address _to,
        uint256 class,
        uint256 nonce,
        uint256 _amount,
        address NFT_address
    ) external returns (bool);

    function redeemBond( address _from, uint256 class, uint256[] calldata nonce, uint256[] calldata _amount) external returns (bool);

    function transferBond(address _from,address _to,uint256[] calldata class,uint256[] calldata nonce,uint256[] calldata _amount) external returns (bool);

    function burnBond(address _from,uint256[] calldata class,uint256[] calldata nonce,uint256[] calldata _amount) external returns (bool);

    event eventIssueBond(address _operator,address _to,uint256 class,uint256 nonce,uint256 _amount);
    event eventRedeemBond(address _operator,address _from,uint256 class,uint256 nonce,uint256 _amount);
    event eventBurnBond(address _operator,address _from,uint256 class,uint256 nonce,uint256 _amount);
    event eventTransferBond(address _operator,address _from,address _to,uint256 class,uint256 nonce,uint256 _amount);
}

interface ISigmoidBonds {
    function isActive(bool _contract_is_active) external returns (bool);

    function setGovernanceContract(address governance_address)
        external
        returns (bool);

    function setExchangeContract(address governance_address)
        external
        returns (bool);

    function setBankContract(address bank_address) external returns (bool);

    function setTokenContract(uint256 class, address contract_address)
        external
        returns (bool);

    function createBondClass(
        uint256 class,
        string calldata bond_symbol,
        uint256 Fibonacci_number,
        uint256 Fibonacci_epoch
    ) external returns (bool);
}

contract ERC659data {
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public _balances;

    mapping(uint256 => mapping(uint256 => uint256)) public _activeSupply;

    mapping(uint256 => mapping(uint256 => uint256)) public _burnedSupply;

    mapping(uint256 => mapping(uint256 => uint256)) public _redeemedSupply;

    mapping(uint256 => address) public _bankAddress;

    mapping(uint256 => string) public _Symbol;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
        public _info;

    mapping(uint256 => uint256) public last_bond_nonce;

    mapping(uint256 => uint256[]) public _nonceCreated;

    uint256[] public _classCreated;

    mapping(uint256 => mapping(uint256 => address))
        public ERC721_token_contract;

    mapping(uint256 => address) public ERC20_token_contract;
}

contract SigmoidBonds is ISigmoidBonds, ERC659data, IERC659 {
    using SafeMath for uint256;

    BondLib[] public bondLib;

    bool public contract_is_active;
    address public governance_contract;
    address public exchange_contract;
    address public bank_contract;
    address public bond_contract;

    mapping(uint256 => uint256) public last_activeSupply;

    mapping(uint256 => uint256) public last_burnedSupply;

    mapping(uint256 => uint256) public last_redeemedSupply;

    mapping(uint256 => uint256) public last_bond_redeemed;
    mapping(uint256 => uint256) public _Fibonacci_number; //controls how many kind of different bond nonce will be issued, =8 means that 8 different bonds nonce will be issued
    mapping(uint256 => uint256) public _Fibonacci_epoch; //controls how much time will be needed before changing the bond nonce.
    mapping(uint256 => uint256) public _genesis_nonce_time; //the timestamp of the first bond nonce issued of a bond class

    uint256[] fibArray = [
        uint256(1),
        1,
        2,
        3,
        5,
        8,
        13,
        21,
        34,
        55,
        89,
        144,
        233,
        377,
        610,
        987,
        1597,
        2584,
        4181
    ];
    struct BondStructData {
        address _to;
        uint256 class;
        uint256 nonce;
        uint256 _amount;
        uint256 factor_p;
    }

    constructor(address governance_address) public {
        governance_contract = governance_address;
        _classCreated = [0, 1, 2, 3];

        _Symbol[0] = "SASH-USD";
        _Fibonacci_number[0] = 7;
        _Fibonacci_epoch[0] = 24 * 60 * 60;
        _genesis_nonce_time[0] = 0;

        _Symbol[1] = "SGM-SASH";
        _Fibonacci_number[1] = 7;
        _Fibonacci_epoch[1] = 24 * 60 * 60;
        _genesis_nonce_time[1] = 0;

        _Symbol[2] = "SGM,SGM";
        _Fibonacci_number[2] = 7;
        _Fibonacci_epoch[2] = 24 * 60 * 60;
        _genesis_nonce_time[2] = 0;

        _Symbol[3] = "SASH,SGM";
        _Fibonacci_number[3] = 7;
        _Fibonacci_epoch[3] = 24 * 60 * 60;
        _genesis_nonce_time[3] = 0;
    }

    function isActive(bool _contract_is_active) public override returns (bool) {
        contract_is_active = _contract_is_active;
        return (contract_is_active);
    }

    function setGovernanceContract(address governance_address) public override returns (bool){
        require(
            msg.sender == governance_contract,
            "ERC659: operator unauthorized"
        );
        governance_contract = governance_address;
        return (true);
    }

    function setExchangeContract(address exchange_address) public override returns (bool){
        require(
            msg.sender == governance_contract,
            "ERC659: operator unauthorized"
        );
        exchange_contract = exchange_address;
        return (true);
    }

    function setBankContract(address bank_address) public override returns (bool){
        require(msg.sender == governance_contract,"ERC659: operator unauthorized");
        bank_contract = bank_address;
        return (true);
    }

    function setTokenContract(uint256 class, address contract_address) public override returns (bool){
        require(
            msg.sender == governance_contract,
            "ERC659: operator unauthorized"
        );
        ERC20_token_contract[class] = contract_address;
        return (true);
    }

    function getNonceCreated(uint256 class) public view override returns (uint256[] memory){
        return _nonceCreated[class];
    }

    function getClassCreated() public view override returns (uint256[] memory) {
        return _classCreated;
    }

    function createBondClass( uint256 class, string memory bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch) public override returns (bool) {
        require( msg.sender == governance_contract, "ERC659: operator unauthorized");
        _Symbol[class] = bond_symbol;
        _Fibonacci_number[class] = Fibonacci_number;
        _Fibonacci_epoch[class] = Fibonacci_epoch;
        _genesis_nonce_time[class] = 0;

        for (uint256 i = 0; i < _classCreated.length; i++) {
            if (i == class) {
                return true;
            }
        }
        _classCreated.push(class);
        return true;
    }

    //allows anyone to read the non-burned and non-redeemed Supply of a given class nonce and bond nonce.
    function activeSupply(uint256 class, uint256 nonce) public view override returns (uint256){
        return _activeSupply[class][nonce];
    }

    //allows anyone to read the redeemed Supply of a given class and bond nonce.
    function burnedSupply(uint256 class, uint256 nonce) public view override returns (uint256)
    {
        return _burnedSupply[class][nonce];
    }

    //allows anyone to read the redeemed Supply of a given class and bond nonce.
    function redeemedSupply(uint256 class, uint256 nonce) public view override returns (uint256)
    {
        return _redeemedSupply[class][nonce];
    }

    //allows anyone to read the total supply of a given class nonce and bond nonce, this include burned and redeemed Supply
    function totalSupply(uint256 class, uint256 nonce) public view override returns (uint256)
    {
        return
            _activeSupply[class][nonce] +
            _burnedSupply[class][nonce] +
            _redeemedSupply[class][nonce];
    }

    //get the total active supply of a bond class
    function batchActiveSupply(uint256 class) public view override returns (uint256)
    {
        uint256 _batchActiveSupply;

        for (uint256 i = 0; i <= last_bond_nonce[class]; i++) {
            _batchActiveSupply +=
                _activeSupply[class][i] +
                _redeemedSupply[class][i];
        }
        return _batchActiveSupply;
    }

    //get the total burned supply of a bond class
    function batchBurnedSupply(uint256 class) public view override returns (uint256)
    {
        uint256 _batchBurnedSupply;

        for (uint256 i = 0; i <= last_bond_nonce[class]; i++) {
            _batchBurnedSupply +=
                _burnedSupply[class][i] +
                _burnedSupply[class][i];
        }
        return _batchBurnedSupply;
    }

    //get the total redeemed supply of a bond class
    function batchRedeemedSupply(uint256 class) public view override returns (uint256)
    {
        uint256 _batchRedeemedSupply;

        for (uint256 i = 0; i <= last_bond_nonce[class]; i++) {
            _batchRedeemedSupply +=
                _redeemedSupply[class][i] +
                _redeemedSupply[class][i];
        }
        return _batchRedeemedSupply;
    }

    //get the total supply of a bond class
    function batchTotalSupply(uint256 class) public view override returns (uint256)
    {
        return
            batchActiveSupply(class) +
            batchBurnedSupply(class) +
            batchRedeemedSupply(class);
    }

    //get the balance of a bond class, a bond nonce of an address
    function balanceOf( address account, uint256 class, uint256 nonce) public view override returns (uint256) {
        require(account != address(0),"ERC659: balance query for the zero address");
        return _balances[account][class][nonce];
    }

    //get a list of the balances of a bond class of an address.
    function batchBalanceOf(address account, uint256 class) public view override returns (uint256[] memory){
        uint256[] memory balancesAllNonce = new uint256[](last_bond_nonce[class]);
        for (uint256 i = 0; i < last_bond_nonce[class]; i++) {
            balancesAllNonce[i] = _balances[account][class][i];
        }
        return (balancesAllNonce);
    }

    function totalBatchBalanceOf(address account, uint256 class) public view override returns (uint256){
        uint256 totalBatchBalance;
        for (uint256 i = 0; i < last_bond_nonce[class]; i++) {
            totalBatchBalance += _balances[account][class][i];
        }

        return (totalBatchBalance);
    }

    function getBondSymbol(uint256 class) public view override returns (string memory)
    {
        return _Symbol[class];
    }

    function get_factor_P(uint256 class, uint256 nonce) public view returns (uint256 factor_P)
    {
        uint256[2] memory needed;
        needed = getBondProgress(class, nonce);
        uint256 total_liquidity = needed[0];
        uint256 total_liquidity_78;
        uint256 total_liquidity_7;
        uint256 average_liquidity;
        if (needed[0] >= needed[1]) {
            return (now);
        } else {
            //if the project is just start, then taken only the avarage liquidity of every bond nonces
            if (last_bond_nonce[class] <= 78) {
                average_liquidity = total_liquidity / last_bond_nonce[class];
            } else {
                //the average newly added liquidity of the last 78 nonce

                for (
                    uint256 i = last_bond_nonce[class] - 78;
                    i <= last_bond_nonce[class];
                    i++
                ) {
                    total_liquidity_78 +=
                        _activeSupply[class][i] +
                        _redeemedSupply[class][i];
                }

                for (
                    uint256 i = last_bond_nonce[class] - 7;
                    i <= last_bond_nonce[class];
                    i++
                ) {
                    total_liquidity_7 +=
                        _activeSupply[class][i] +
                        _redeemedSupply[class][i];
                }

                //get the average liquidity estimation with standard deviation
                average_liquidity =
                    ((total_liquidity / last_bond_nonce[class]) * 158) /
                    1e3 +
                    ((total_liquidity_78 / 78) * 682) /
                    1e3 +
                    ((total_liquidity_7 / 7) * 158) /
                    1e3;
            }

            //calculate P from the addtional liquidity needed, the average liquidity and the interval between two bonds
            factor_P =
                needed[1] -
                (needed[0] / average_liquidity) *
                _Fibonacci_epoch[class];
        }
    }

    function getBondInfo(uint256 class, uint256 nonce) public view override returns (
            string memory BondSymbol,
            uint256 timestamp,
            uint256 info2,
            uint256 info3,
            uint256 info4,
            uint256 info5,
            uint256 info6
        )
    {
        BondSymbol = _Symbol[class];
        timestamp = _info[class][nonce][1];
        info2 = _info[class][nonce][2];
        info3 = _info[class][nonce][3];
        info4 = _info[class][nonce][4];
        info5 = _info[class][nonce][5];
        info6 = _info[class][nonce][6];
    }

    function getBondProgress(uint256 class, uint256 nonce) public view override returns (uint256[2] memory)
    {
        uint256 total_liquidity = last_activeSupply[class];
        uint256 needed_liquidity = last_activeSupply[class];

        for (
            uint256 i = last_bond_redeemed[class];
            i <= last_bond_nonce[class];
            i++
        ) {
            total_liquidity +=
                _activeSupply[class][i] +
                _redeemedSupply[class][i];
        }

        for (uint256 i = last_bond_redeemed[class]; i <= nonce; i++) {
            needed_liquidity +=
                (_activeSupply[class][i] + _redeemedSupply[class][i]) *
                2;
        }

        return [total_liquidity, needed_liquidity];
    }

    function getBatchBondProgress(uint256 class, uint256 nonce) public view override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory have = new uint256[](last_bond_nonce[class]);
        uint256[] memory need = new uint256[](last_bond_nonce[class]);
        for (uint256 n = 0; n < last_bond_nonce[class]; n++) {
            uint256 total_liquidity = last_activeSupply[class];
            uint256 needed_liquidity = last_activeSupply[class];

            for (
                uint256 i = last_bond_redeemed[class];
                i <= last_bond_nonce[class];
                i++
            ) {
                total_liquidity +=
                    _activeSupply[class][i] +
                    _redeemedSupply[class][i];
            }

            for (uint256 i = last_bond_redeemed[class]; i <= nonce; i++) {
                needed_liquidity +=
                    (_activeSupply[class][i] + _redeemedSupply[class][i]) *
                    2;
            }

            (total_liquidity, needed_liquidity);
            have[n] = total_liquidity;
            need[n] = needed_liquidity;
        }

        return (have, need);
    }

    //check if the bond is redeemable
    function bondIsRedeemable(uint256 class, uint256 nonce) public view override returns (bool){
        if (last_bond_redeemed[class] >= nonce) {
            return (true);
        }

        if (uint256(_info[class][nonce][1]) < now) {
            uint256 total_liquidity = last_activeSupply[class];
            uint256 needed_liquidity = last_activeSupply[class];

            for (
                uint256 i = last_bond_redeemed[class];
                i <= last_bond_nonce[class];
                i++
            ) {
                total_liquidity +=
                    _activeSupply[class][i] +
                    _redeemedSupply[class][i];
            }

            for (uint256 i = last_bond_redeemed[class]; i <= nonce; i++) {
                needed_liquidity +=
                    (_activeSupply[class][i] + _redeemedSupply[class][i]) *
                    2;
            }

            if (total_liquidity >= needed_liquidity) {
                return (true);
            } else {
                return (false);
            }
        } else {
            return (false);
        }
    }

    //economise looping when check the liquidity of a bond
    function _writeLastLiquidity(uint256 class, uint256 nonce) internal returns (bool){
        uint256 total_liquidity;
        //uint256 available_liquidity;

        for (uint256 i = last_bond_redeemed[class]; i < nonce; i++) {
            total_liquidity +=
                last_activeSupply[class] +
                _activeSupply[class][i] +
                _redeemedSupply[class][i];
        }
        last_activeSupply[class] = total_liquidity;
    }

    //if the total supply of a bond nonce is 0, this function will be called to create a new bond nonce
    function _createBond( address _to, uint256 class, uint256 nonce, uint256 _amount ) private returns (bool) {
        if (last_bond_nonce[class] < nonce) {
            last_bond_nonce[class] = nonce;
        }
        _nonceCreated[class].push(nonce);
        _info[class][nonce][1] =
            _genesis_nonce_time[class] +
            (nonce) *
            _Fibonacci_epoch[class];
        _balances[_to][class][nonce] += _amount;
        _activeSupply[class][nonce] += _amount;
        emit eventIssueBond(msg.sender, _to, class, nonce, _amount);
        return (true);
    }

    function _issueBond(address _to,uint256 class,uint256 nonce,uint256 _amount) private returns (bool) {
        if (totalSupply(class, nonce) == 0) {
            _createBond(_to, class, nonce, _amount);
            return (true);
        } else {
            _balances[_to][class][nonce] += _amount;
            _activeSupply[class][nonce] += _amount;
            emit eventIssueBond(
                msg.sender,
                _to,
                class,
                last_bond_nonce[class],
                _amount
            );
            return (true);
        }
    }

    function _issueNfTBond(address _to,uint256 class,uint256 nonce,uint256 _amount,address NFT_address) private returns (bool) {
        if (_balances[_to][class][nonce] == 0) {
            _balances[_to][class][nonce] += _amount;
            _activeSupply[class][nonce] += _amount;
            ERC721_token_contract[class][nonce] = NFT_address;
            emit eventIssueBond(msg.sender, _to, class, nonce, _amount);
            return (true);
        }
    }

    function _redeemBond(address _from,uint256 class,uint256 nonce,uint256 _amount) private returns (bool) {
        _balances[_from][class][nonce] -= _amount;
        _activeSupply[class][nonce] -= _amount;
        _redeemedSupply[class][nonce] += _amount;
        emit eventRedeemBond(msg.sender, _from, class, nonce, _amount);
        return (true);
    }

    function _transferBond(address _from,address _to,uint256 class,uint256 nonce,uint256 _amount ) private returns (bool) {
        _balances[_from][class][nonce] -= _amount;
        _balances[_to][class][nonce] += _amount;
        emit eventTransferBond(msg.sender, _from, _to, class, nonce, _amount);
        return (true);
    }

    function _burnBond(address _from,uint256 class,uint256 nonce,uint256 _amount) private returns (bool) {
        _balances[_from][class][nonce] -= _amount;
        emit eventBurnBond(msg.sender, _from, class, nonce, _amount);
        return (true);
    }
    function getBondReviewData(address _to,uint256 class,uint256 _amount) external returns (BondStructData[] memory) {
        uint256 amount_out_eponge;
        if (_genesis_nonce_time[class] == 0) {
            _genesis_nonce_time[class] = now - (now % _Fibonacci_epoch[class]);
        }
        uint256 now_nonce = (now - _genesis_nonce_time[class]) / _Fibonacci_epoch[class];

        //the first fibonacci numbers is to calculate the percentage and the distribution of the bond nonce.
        for (uint256 i = 0; i < _Fibonacci_number[class]; i++) {
            amount_out_eponge += fibArray[i];
        }
        amount_out_eponge = (_amount * 1e6) / amount_out_eponge;

        BondStructData[] memory bonds = new BondStructData[](
            _Fibonacci_number[class]
        );
        //the second fibonacci numbers calculation issues bonds to user.
        for (uint256 i = 0; i < _Fibonacci_number[class]; i++) {
            bonds[i] = BondStructData(
                _to,
                class,
                now_nonce + fibArray[i],
                (amount_out_eponge * fibArray[i]) / 1e6,
                get_factor_P(class, now_nonce + fibArray[i])
            );
        }
        return bonds;
    }

    //Only bank contract can call this function, the calling of this function requires a deposit from the user to the bonk contract.
    function issueBond(address _to,uint256 class,uint256 _amount ) external override returns (bool) {
        require(contract_is_active == true);
        require(msg.sender == bank_contract, "ERC659: operator unauthorized");
        require(_to != address(0), "ERC659: issue bond to the zero address");
        require(_amount >= 1 * 10**16, "ERC659: invalid amount");
        if (_genesis_nonce_time[class] == 0) {
            _genesis_nonce_time[class] = now - (now % _Fibonacci_epoch[class]);
        }
        uint256 now_nonce = (now - _genesis_nonce_time[class]) /
            _Fibonacci_epoch[class];

        //the first fibonacci numbers is to calculate the percentage and the distribution of the bond nonce.
        uint256 FibonacciTimeEponge0 = 1;
        uint256 FibonacciTimeEponge1 = 2;
        uint256 FibonacciTimeEponge;
        uint256 amount_out_eponge;
        for (uint256 i = 0; i < _Fibonacci_number[class]; i++) {
            if (i == 0) {
                FibonacciTimeEponge = 1;
            } else {
                if (i == 1) {
                    FibonacciTimeEponge = 2;
                } else {
                    FibonacciTimeEponge = (FibonacciTimeEponge0 +
                        FibonacciTimeEponge1);
                    FibonacciTimeEponge0 = FibonacciTimeEponge1;
                    FibonacciTimeEponge1 = FibonacciTimeEponge;
                }
            }
            amount_out_eponge += FibonacciTimeEponge;
        }

        amount_out_eponge = (_amount * 1e6) / amount_out_eponge;

        //the second fibonacci numbers calculation issues bonds to user.
        FibonacciTimeEponge = 0;
        FibonacciTimeEponge0 = 1;
        FibonacciTimeEponge1 = 2;
        for (uint256 i = 0; i < _Fibonacci_number[class]; i++) {
            if (i == 0) {
                FibonacciTimeEponge = 1;
            } else {
                if (i == 1) {
                    FibonacciTimeEponge = 2;
                } else {
                    FibonacciTimeEponge = (FibonacciTimeEponge0 +
                        FibonacciTimeEponge1);
                    FibonacciTimeEponge0 = FibonacciTimeEponge1;
                    FibonacciTimeEponge1 = FibonacciTimeEponge;
                }
            }
            require(
                _issueBond(
                    _to,
                    class,
                    (now_nonce + FibonacciTimeEponge) * 6,
                    (amount_out_eponge * FibonacciTimeEponge) / 1e6
                ) == true
            );
        }
        return (true);
    }

    function issueNFTBond( address _to, uint256 class, uint256 nonce, uint256 _amount, address NFT_address) external override returns (bool) {
        require(contract_is_active == true);
        require(msg.sender == bank_contract, "ERC659: operator unauthorized");
        require(_to != address(0), "ERC659: issue bond to the zero address");
        _issueNfTBond(_to, class, nonce, _amount, NFT_address);

        return (true);
    }

    //redeem a list of bonds. Only bank contract or the from address can call this function. only the redeemable bond nonce can be used to call this function.
    function redeemBond(address _from,uint256 class,uint256[] calldata nonce,uint256[] calldata _amount) external override returns (bool) {
        require(contract_is_active == true);
        require(
            msg.sender == bank_contract || msg.sender == _from,
            "ERC659: operator unauthorized"
        );
        for (uint256 i = 0; i < nonce.length; i++) {
            require(
                _balances[_from][class][nonce[i]] >= _amount[i],
                "ERC659: not enough bond for redemption"
            );
            require(
                bondIsRedeemable(class, nonce[i]) == true,
                "ERC659: can't redeem bond before it's redemption day"
            );
            require(_redeemBond(_from, class, nonce[i], _amount[i]));

            if (last_bond_redeemed[class] < nonce[i]) {
                _writeLastLiquidity(class, nonce[i]);
                last_bond_redeemed[class] = nonce[i];
            }
        }

        return (true);
    }

    //transfer a list of bonds. Only bank contract or exchange contract can call this function.
    function transferBond(address _from,address _to,uint256[] calldata class,uint256[] calldata nonce,uint256[] calldata _amount) external override returns (bool) {
        require(contract_is_active == true);
        require(msg.sender == _from || (msg.sender == bank_contract || msg.sender == exchange_contract), "ERC659: operator unauthorized");

        for (uint256 n = 0; n < nonce.length; n++) {
            require(_balances[_from][class[n]][nonce[n]] >= _amount[n],"ERC659: not enough bond to transfer");
            require(_to != address(0), "ERC659: cant't transfer to zero bond, use 'burnBond()' instead");
            require(_transferBond(_from, _to, class[n], nonce[n], _amount[n]));
        }
        return (true);
    }

    //burn a list of bonds. Only bank contract or _from address can call this function.
    function burnBond(address _from,uint256[] calldata class,uint256[] calldata nonce,uint256[] calldata _amount) external override returns (bool) {
        require(contract_is_active == true);
        for (uint256 n = 0; n < nonce.length; n++) {
            require(
                msg.sender == bank_contract || msg.sender == _from,
                "ERC659: operator unauthorized"
            );
            require(
                _balances[_from][class[n]][nonce[n]] >= _amount[n],
                "ERC659: not enough bond to burn"
            );
            require(_burnBond(_from, class[n], nonce[n], _amount[n]));
        }
        return (true);
    }
    uint256[] arr;
    function setData( address _bondAddress, uint256 _eta, uint256[] storage _bondAmount, uint256[] storage _bondClass, uint256[] storage _bondNonce) internal pure returns (BondTypes memory bonds) {
        bonds.bondAddress = _bondAddress;
        bonds.eta = _eta;
        bonds.bondAmount = _bondAmount;
        bonds.bondClass = _bondClass;
        bonds.bondNonce = _bondNonce;
    }

    function writeInfo(ERC20LOAN memory _ERC20Loan) public override returns (bool){
        if (bondLib.length == 0) {
            bondLib.push(
                BondLib({
                    types: "ERC20Loan",
                    erc20loans: _ERC20Loan,
                    bonds: setData(
                        _ERC20Loan.bondAddress,
                        _ERC20Loan.loanDuration,
                        arr,
                        arr,
                        arr
                    )
                })
            );
            return (true);
        }
        for (uint256 i = 0; i < bondLib.length; i++) {
            if (bondLib[i].erc20loans.auctionStatus == false) {
                bondLib[i].erc20loans = _ERC20Loan;
                return (true);
            }
        }
        bondLib.push(
            BondLib({
                types: "ERC20Loan",
                erc20loans: _ERC20Loan,
                bonds: setData(
                    _ERC20Loan.bondAddress,
                    _ERC20Loan.loanDuration,
                    arr,
                    arr,
                    arr
                )
            })
        );
        return (true);
    }
}