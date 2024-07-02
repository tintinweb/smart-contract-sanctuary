// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;
import "./BEP20.sol";

contract gWDTToken is BEP20 {

    mapping (address => bool) public allowedCallers;
    mapping (address => bool) public allowedMinters;

    address public operator;

    constructor() BEP20('gWDT Token','gWDT') {
        operator = msg.sender;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(allowedCallers[msg.sender], "only allowed transfers");
        super._transfer(sender,recipient,amount);
    }

    function mint(address _to, uint256 _amount) public {
        require(allowedMinters[msg.sender], "only allowed minter");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        require(allowedMinters[msg.sender], "only allowed minter");
        _burn(_from,_amount);
    }

    function allowMinter(address _minter, bool _val) public onlyOperator {
        allowedMinters[_minter] = _val;
    }

    function allowCaller(address _caller, bool _val) public onlyOperator {
        allowedCallers[_caller] = _val;
    }

    function changeOperator(address _newOperator) public onlyOperator {
        operator = _newOperator;
    }

    modifier onlyOperator {
        require(msg.sender == operator, "only op");
        _;
    }
}