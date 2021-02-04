pragma solidity >=0.6.0 <0.8.0;


contract DAOTest {
    
    
    
    function doIt(address recipient,bytes calldata _transactionData) external payable {
        
        
        // this call is as generic as any transaction. It sends all gas and
            // can do everything a transaction can do. It can be used to reenter
            // the DAO. The `p.proposalPassed` variable prevents the call from 
            // reaching this line again
            
            (bool success, ) = recipient.call.value(msg.value)(_transactionData);
            require(success,"big fuckup");
            
            
           
                
                
                
    }
    
    
    function what(address _who) pure external returns (bytes memory) {
        
        
        bytes memory payload = abi.encodeWithSignature("transferOwnership(address)", _who);
        
        return payload;
        
    }
    
    
}
