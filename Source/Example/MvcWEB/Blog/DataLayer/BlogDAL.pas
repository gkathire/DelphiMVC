unit BlogDAL;

interface

uses MvcDB, BOClasses, Generics.Collections, SynDB , MvcCommon, MvcLog , MvcDBCommon;

type
  TBlogDAL = class
  private
    FDBPost:TMVcDB<TPost>;
  public
    function FindPostById(AId:LongInt) : TPost;
    function DeletePostById(AId:LongInt) : Boolean;
    function UpdatePost(APost:TPost):Boolean;
    function AddPost(APost:TPost):Boolean;
    function ListPost:TMvcList<TPost>;overload;
    constructor Create;
  end;

implementation

function TBlogDAL.FindPostById(AId:LongInt) : TPost;
begin
  Result:= FDBPost.FirstById(AId);
end;

function TBlogDAL.DeletePostById(AId:LongInt) : Boolean;
begin
  Result:= FDBPost.DeleteById(AId) > 0;
end;

function TBlogDAL.UpdatePost(APost:TPost):Boolean;
begin
  Result:= FDBPost.Update(APost) > 0;
end;

function TBlogDAL.AddPost(APost:TPost):Boolean;
begin
  Result:= FDBPost.Insert(APost) > 0;
end;

function TBlogDAL.ListPost:TMvcList<TPost>;
begin
  Result:= FDBPost.Select();
end;

constructor TBlogDAL.Create;
var
  DefaultConnection:TSQLDBConnection;
begin
  inherited Create;
  DefaultConnection := LoadConnectionFromConfig('sqlite');
  FDBPost := TMVcDB<TPost>.Create(DefaultConnection);
end;


end.
