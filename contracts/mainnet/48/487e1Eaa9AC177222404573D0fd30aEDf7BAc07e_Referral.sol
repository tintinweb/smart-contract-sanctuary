// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Referral {

    mapping( address=>bytes12 ) private _registers;
    mapping( bytes12=>address ) private _referrals;
    uint private _count;
    
    function issue(address account) public returns(bool){
        require( account != address(0x0), "REF : Account is Zero address" );
        require( _registers[account] == 0, "REF : Already Registry" );
        
        uint salt = 0;
        while( true ){
            bytes12 code = _issueReferralCode(account, salt);
            if( _referrals[code] == address(0x0) ){
                _referrals[code] = account;
                _registers[account] = code;    
                break;
            }
            salt++;
        }
        _count++;
        return true;
    }

    function _issueReferralCode( address sender, uint salt ) private pure returns( bytes12 ){
        return bytes12(bytes32(uint(keccak256(abi.encodePacked(sender, salt)))));
    }
    
    function validate( bytes12 code ) public view returns( address ){
        return _referrals[code];
    }
    
    function referralCode( address account ) public view returns( bytes12 ){
        return _registers[account];
    }

}

