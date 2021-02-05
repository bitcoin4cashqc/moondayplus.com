pragma solidity >=0.6.0 <0.8.0;


contract DAOTest {
    
    uint256 public W = 40;
    
    function doIt(address recipient,bytes calldata _transactionData) external payable {
        
        
        // this call is as generic as any transaction. It sends all gas and
            // can do everything a transaction can do. It can be used to reenter
            // the DAO. The `p.proposalPassed` variable prevents the call from 
            // reaching this line again
            
            (bool success, ) = recipient.call.value(msg.value)(_transactionData);
            require(success,"big fuckup");
            
            
           
                
                
                
    }
    
    
    function what(uint256 _how) pure external returns (bytes memory) {
        
        
        bytes memory payload = abi.encodeWithSignature("changeHoldersW(uint256)", _how);
        
        return payload;
        
    }
    
    
    //admin like dao functions change % of holders
     function changeHoldersW(uint256 _W) external {
        
        require(msg.sender == address(this),"the fuck");
         
        W = _W;
     }
    
    
}
