program MvcDBDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils, BOClasses ,MvcDB, SynDBSQLite3 ;

var
  postDB:TMVcDB<TPost>;
  db:TMvcDBBase;
  dbConn:TSQLDBSQLite3Connection;
  dbProp:TSQLDBSQLite3ConnectionProperties;

procedure InitDB;
begin
  dbProp:=TSQLDBSQLite3ConnectionProperties.Create( GetCurrentDir +'\DataFiles\BlogDB.s3db','','','');
  dbConn:=TSQLDBSQLite3Connection.Create(dbProp);
  db:=TMvcDBBase.Create(dbConn);
  postDB:=TMVcDB<TPost>.Create(dbConn);
end;

procedure InitTest;
begin
  db.Delete('sqlite_sequence','');
  db.Delete('Post','');
  db.Delete('Comment','');
  db.Delete('User','');
end;


procedure InsertTest;
var
  post,post2:TPost;
begin
  post:=TPost.Create;
  post.Title := 'FirstTitle';
  post.Body := 'FirstBody';
  postDB.Insert(post);

  post2 := postDB.FirstById(1);

  post2 := postDB.First('PostId = 1');

  //post2.Title := 'FirstTitleUpdated';
  //post2.Body := 'FirstBodyUpdated';
  //postDB.Update(post2);
end;

begin
  InitDB;
  InitTest;
  InsertTest;
end.
