/**
 *Submitted for verification at FtmScan.com on 2022-01-21
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}
interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement(string memory confirm) external;

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
        emit OwnershipPulled( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement(string memory confirm) public virtual override onlyOwner() {
        require(
            keccak256(abi.encodePacked(confirm)) == keccak256(abi.encodePacked("confirm renounce")),
            "Ownable: renouce needs 'confirm renounce' as input"
        );
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
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
interface ITORMintStrategy{
    function tryMint(address recipient,uint amount) external returns(bool);
}
contract TORWhitelist is ITORMintStrategy,Ownable{
    using SafeMath for uint;
    mapping(address=>uint) public minted;
    uint public limitPerAccount=5000*1e18+1;
    uint public numberLimit=400;
    uint public totalNumber;
    address public TORMinter;
    function setTORMinter(address _TORMinter) external onlyOwner(){
        require(_TORMinter!=address(0),"invalid TORMinter address");
        TORMinter=_TORMinter;
    }
    function setLimit(uint _numberLimit,uint _limitPerAccount) external onlyOwner(){
        numberLimit=_numberLimit;
        limitPerAccount=_limitPerAccount;
    }
    function add(address wallet) external onlyOwner(){
        require(totalNumber<numberLimit,"too many wallets");
        require(minted[wallet]==0,"wallet exists");
        minted[wallet]=1;
        totalNumber=totalNumber.add(1);
    }
    function remove(address wallet) external onlyOwner(){
        require(minted[wallet]!=0,"wallet not found");
        require(minted[wallet]==1,"wallet minted already");
        delete minted[wallet];
        totalNumber=totalNumber.sub(1);
    }
    function tryMint(address wallet,uint amount) override external returns(bool){
        require(amount>0,"amount must be positive");
        require(msg.sender==TORMinter&&TORMinter!=address(0),"only TORMinter can tryMint");
        require(minted[wallet]!=0,"wallet not found");
        require(minted[wallet].add(amount)<=limitPerAccount,"per account limit exceeds");
        minted[wallet]=minted[wallet].add(amount);
        return true;
    }
}