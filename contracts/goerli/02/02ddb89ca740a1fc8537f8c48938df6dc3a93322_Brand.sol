/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-05-20
*/

pragma solidity ^0.6.0;
//SPDX-License-Identifier: UNLICENSED
interface IaddressController {
    function isManager(address _mAddr) external view returns(bool);
    function getAddr(string calldata _name) external view returns(address);
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}
contract Brand{
    using Address for address;
    
    IaddressController public addrc;
    
    mapping(uint256 => bool) public isRegisterBrand;
    mapping(uint256 => Brand_S) public brand;
    struct Brand_S{
        string name;
        string description;
        address feetoken;
        uint256 fee; // amount of fee token
        
    }
    
    event RegisteredBrand(uint256 _bID,string  _description,address _feeToken,uint256 _fee,string _name);
    event UpdateBrand(uint256 _bID,string  _description,address _feeToken,uint256 _fee,string _name);
    event DelBrand(uint256 _bID);
    event SetFee(uint256 _bID,uint256 _fee);
    event SetFeeToken(uint256 _bID,address _feeToken);
    event SetDescription(uint256 _bID,string  _description);
    
    
    constructor(IaddressController _addrc) public{
        addrc = _addrc;
    }
    
    function registeredBrand(uint256 _bID,string  memory _description,address _feeToken,uint256 _fee,string memory _name) public onlyManager{
        require(!isRegisterBrand[_bID],"already registered Brand id");
        require(_feeToken.isContract() || _feeToken == address(1),"_feeToken not contract address");
        
        brand[_bID] = Brand_S({
            name:_name,
            description :_description,
            feetoken:_feeToken,
            fee :_fee
        });
        
        isRegisterBrand[_bID] = true;
        
        emit RegisteredBrand(_bID,_description,_feeToken,_fee,_name);
    }
    
    function updateBrand(uint256 _bID,string  memory _description,address _feeToken,uint256 _fee,string memory _name) public onlyManager{
        require(isRegisterBrand[_bID],"Brand not registered");
        require(_feeToken.isContract() || _feeToken == address(1),"_feeToken not contract address");
        
        brand[_bID] = Brand_S({
            name:_name,
            description :_description,
            feetoken:_feeToken,
            fee :_fee
        });
        
        emit UpdateBrand(_bID,_description,_feeToken,_fee, _name);
    }
    
    function getBrand(uint256 _bID) public view returns(string memory _description,address _feeToken,uint256 _fee,bool _isRegester ){
        _description = brand[_bID].description;
        _feeToken = brand[_bID].feetoken;
        _fee = brand[_bID].fee;
        _isRegester = isRegisterBrand[_bID];
    }
    
    
    function setFee(uint256 _bID,uint256 _fee) public onlyManager{
        require(isRegisterBrand[_bID],"Brand not registered");
        brand[_bID].fee = _fee;
        
        emit SetFee(_bID,_fee);
    }
     
     
    function setFeeToken(uint256 _bID,address _feeToken) public onlyManager{
        require(isRegisterBrand[_bID],"Brand not registered");
        require(_feeToken.isContract() || _feeToken == address(1),"_feeToken not contract address");
        brand[_bID].feetoken = _feeToken;
        
        emit SetFeeToken(_bID,_feeToken);
    }
    
    function setDescription(uint256 _bID,string  memory _description) public onlyManager{
        require(isRegisterBrand[_bID],"Brand not registered");
        brand[_bID].description = _description;
        
        emit SetDescription(_bID,_description);
    }
    
    function delBrand(uint256 _bID) public onlyManager{
        require(isRegisterBrand[_bID],"Brand not registered");
        isRegisterBrand[_bID] = false;
        
        emit DelBrand(_bID);
    }
    
    
    function nameAddr(string memory _name) public view returns(address){
        return addrc.getAddr(_name);
    }
    
    modifier onlyManager(){
        require(addrc.isManager(msg.sender),"onlyManager");
        _;
    }
}