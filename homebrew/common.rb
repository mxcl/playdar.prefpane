require 'formula'

PPP_CELLAR = Pathname.new(__FILE__).realpath.dirname.parent+'build/Cellar'
ENV['PPP_CELLAR'] = PPP_CELLAR

class PlaydarPrefPaneFormula <Formula
  def prefix
    PPP_CELLAR+name
  end
  def keg_only?
    true
  end
end