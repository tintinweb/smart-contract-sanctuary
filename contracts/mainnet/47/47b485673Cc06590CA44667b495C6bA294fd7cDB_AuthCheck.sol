/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity >=0.7.0 <0.9.0;

abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
}

abstract contract DSProxy {
    DSAuthority public authority;
}

contract AuthCheck {
        function canCall(address src, address dst, bytes4 sig) public virtual returns (bool) {
            (bool success,) = address(this).call(
                abi.encodeWithSignature("_canCall(address,address,bytes4)", src, dst, sig)
            );
            if (success) return _canCall(src, dst, sig);
            return false;
        }
        
        function _canCall(address src, address dst, bytes4 sig) public view virtual returns (bool) {
            address _auth = address(DSProxy(dst).authority());
            if (_auth == address(0)) return false;
            return DSAuthority(_auth).canCall(src, dst, sig);
        }
}