@IsTest
private class InstallationTests {

    private static final String STRING_TEST = 'TEST';
    private static final String NEW_STATUS = 'New';
    private static final String WORKING = 'Working';
    private static final String CLOSED = 'Closed';
    private static final String REPAIR = 'Repair';
    private static final String REQUEST_ORIGIN = 'Web';
    private static final String REQUEST_TYPE = 'Routine Maintenance';
    private static final String REQUEST_SUBJECT = 'AMC Spirit';
    public static String CRON_EXP = '0 0 1 * * ?';


    
    static testmethod void testMaintenanceRequestNegative() {
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        Id vehicleId = vehicle.Id;

        Product2 equipment = createEquipment();
        insert equipment;
        Id equipmentId = equipment.Id;

        Case r = createMaintenanceRequest(vehicleId, equipmentId);
        insert r;
        Work_Part__c w = createWorkPart(equipmentId, r.Id);
        insert w;

        Test.startTest();
        r.Status = WORKING;
        update r;
        Test.stopTest();

        List<case> allRequest = [SELECT Id
                                 FROM Case];
        Work_Part__c workPart = [SELECT Id
                                 FROM Work_Part__c
                                 WHERE Maintenance_Request__c =: r.Id];
        System.assert(workPart != null);
        System.assert(allRequest.size() == 1);
    }

    
    static testmethod void testWarehouseSync() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        String jobId = System.schedule('WarehouseSyncSchedules',
                                       CRON_EXP, 
                                       new WarehouseSyncSchedule());   
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger
                          WHERE id = :jobId];

        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }    


    private static Vehicle__c createVehicle() {
        Vehicle__c v = new Vehicle__c(Name = STRING_TEST);
        return v;
    }

    private static Product2 createEquipment() {
        Product2 p = new Product2(Name = STRING_TEST,
                                  Lifespan_Months__c = 10,
                                  Maintenance_Cycle__c = 10,
                                  Replacement_Part__c = true);
        return p;
    }

    private static Case createMaintenanceRequest(Id vehicleId, Id equipmentId) {
        Case c = new Case(Type = REPAIR,
                          Status = NEW_STATUS,
                          Origin = REQUEST_ORIGIN,
                          Subject = REQUEST_SUBJECT,
                          Equipment__c = equipmentId,
                          Vehicle__c = vehicleId);
        return c;
    }

    private static Work_Part__c createWorkPart(Id equipmentId, Id requestId) {
        Work_Part__c wp = new Work_Part__c(Equipment__c = equipmentId,
                                           Maintenance_Request__c = requestId);
        return wp;
    }
}