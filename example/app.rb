require '../lib/shenmegui'

ShenmeGUI.app(title: 'test application') do
  form title: 'test', resizable: true do
    button('open file').onclick { @text.text = get_open_file_name || ''; @i.src=@text.text}
    @sel = select %w{1 2 3}

    radio %w{option1 option2 option3}, arrange: 'horizontal'

    radio %w{option7 option8 option9}, checked: 'option9'

    button('alert').onclick { alert 'test message'}

    @b = button 'button1'
    @b.onclick do
      @b.text = "clicked"
      @text << "ok"
      @t.text[0] = '1'
      @sel.options.pop
    end

    stack do
      label 'a textarea:'
      @text = textarea('default', width: '100%')
      @text.onselect do
        p this.text[this.selection[0]...this.selection[1]]
      end
    end
    
    @i = image "http://s.amazeui.org/media/i/demos/bw-2014-06-19.jpg"
    @src = textline @i.src
    @src.onchange do
      @i.src = @src.text
    end

    @t = textline 'textline'
    @t.oninput do
      @b.text = this.text
    end

    @pro = progress 15
    button('-').onclick{ @pro.percent -= 5}
    button('+').onclick{ @pro.percent += 5}

    checkbox ['check me', 'and me'], checked:['check me']

    @table = table [['column 1','column 2'],['row','row']], :editable => false
    @table.tap do |t|
      t.column_names = ['c1', 'c2']
      t.row_names_enum = (1..Float::INFINITY).to_enum
      t.column_names_enum = (1..Float::INFINITY).lazy.collect{|x| "column #{x}"}
      t << [3, 4]
    end
    size = 2
    button('test add new row').onclick { @table << ['new row']*size; size+= 1}
  end

end

ShenmeGUI.enable_debugging
ShenmeGUI.open_browser

ShenmeGUI.start!
